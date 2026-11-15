<#
.SYNOPSIS
    Assembles the working application folder build/app with the bundled
    Python and PostgreSQL runtimes.

.DESCRIPTION
    Reads packaging/runtimes.json, makes sure every archive is present in the
    build cache (cache/build/runtimes) with the pinned size and SHA-256, and
    only then unpacks the selected parts into a staging folder inside build/.
    The previous build/app is preserved as a uniquely named backup before
    the staged folder is moved into place. A failed move attempts rollback.

    Layout of build/app:
        runtime/python/   embeddable Python; its launcher is djarvis-core.exe
        runtime/pgsql/    PostgreSQL bin, lib and share only
        licenses/<name>/  license files taken from each archive
        Djarvis.exe ...   the Windows UI release, when it has been built

    Nothing downloaded is executed or unpacked before its hash matches.
    Works in Windows PowerShell 5.1 and PowerShell 7.

.PARAMETER Manifest
    Runtime manifest. Defaults to packaging/runtimes.json.

.PARAMETER UiRelease
    Folder with the Windows UI release. Defaults to
    ui/build/windows/x64/runner/Release.

.PARAMETER Offline
    Never download: fail if an archive is missing from the cache or does not
    match the manifest.
#>
[CmdletBinding()]
param(
    [string]$Manifest,
    [string]$UiRelease,
    [switch]$Offline
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Net.Http

$repoRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
if (-not $Manifest) {
    $Manifest = Join-Path $PSScriptRoot 'runtimes.json'
}
$cacheDir = Join-Path $repoRoot 'cache\build\runtimes'
$buildDir = Join-Path $repoRoot 'build'
$appDir = Join-Path $buildDir 'app'
$uiReleaseDir = if ($UiRelease) {
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($UiRelease)
}
else {
    Join-Path $repoRoot 'ui\build\windows\x64\runner\Release'
}

function Write-Step {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Assert-Field {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Context
    )
    if (-not ($Object.PSObject.Properties.Name -contains $Name)) {
        throw "Manifest: '$Context' has no field '$Name'."
    }
    return $Object.$Name
}

function Assert-RelativePath {
    # Accepts a plain relative path made of ordinary segments only.
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Path,
        [Parameter(Mandatory = $true)][string]$Context
    )
    $normalized = $Path.Replace('\', '/')
    if ($normalized.StartsWith('/') -or $normalized.Contains(':')) {
        throw "${Context}: path '$Path' must be relative."
    }
    foreach ($segment in $normalized.Split('/')) {
        if ($segment -eq '..' -or $segment -eq '.' -or $segment -match '[<>:"|?*\x00-\x1f]' -or $segment -match '[ .]$' -or $segment -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)') {
            throw "${Context}: path '$Path' must not contain '.' or '..' segments."
        }
    }
    return $normalized.Trim('/')
}

function Read-Manifest {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Manifest not found: '$Path'."
    }
    $data = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    $schema = Assert-Field $data 'schema' 'manifest'
    if ($schema -ne 1) {
        throw "Manifest: unsupported schema '$schema' (expected 1)."
    }
    $items = @(Assert-Field $data 'runtimes' 'manifest')
    if ($items.Count -eq 0) {
        throw 'Manifest: no runtimes listed.'
    }

    $names = @{}
    $targets = @{}
    foreach ($item in $items) {
        $name = [string](Assert-Field $item 'name' 'runtime')
        if ($name -notmatch '^[a-z][a-z0-9-]*$') {
            throw "Manifest: invalid runtime name '$name'."
        }
        if ($names.ContainsKey($name)) {
            throw "Manifest: runtime '$name' is listed twice."
        }
        $names[$name] = $true

        [void](Assert-Field $item 'version' $name)
        $url = [string](Assert-Field $item 'url' $name)
        $uri = $null
        if (-not [System.Uri]::TryCreate($url, [System.UriKind]::Absolute, [ref]$uri) -or
            $uri.Scheme -ne 'https' -or $uri.UserInfo -or -not $uri.IsDefaultPort -or
            $uri.Host -notin @('www.python.org', 'get.enterprisedb.com', 'download.visualstudio.microsoft.com')) {
            throw "Manifest: '$name' url must be https on an approved host, without credentials or a custom port."
        }
        $file = [string](Assert-Field $item 'file' $name)
        if ($file -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*\.(zip|vsix)$') {
            throw "Manifest: '$name' file name '$file' is not a plain .zip or .vsix name."
        }
        $size = [int64](Assert-Field $item 'size' $name)
        if ($size -le 0) {
            throw "Manifest: '$name' size must be positive."
        }
        $sha = [string](Assert-Field $item 'sha256' $name)
        if ($sha -notmatch '^[0-9a-f]{64}$') {
            throw "Manifest: '$name' sha256 must be 64 lowercase hex characters."
        }

        $extract = Assert-Field $item 'extract' $name
        [void](Assert-RelativePath ([string](Assert-Field $extract 'root' "$name.extract")) "Manifest '$name' root")
        $target = Assert-RelativePath ([string](Assert-Field $extract 'target' "$name.extract")) "Manifest '$name' target"
        if (-not $target.StartsWith('runtime/')) {
            throw "Manifest: '$name' target must be under runtime/."
        }
        if ($targets.ContainsKey($target)) {
            throw "Manifest: target '$target' is used twice."
        }
        $targets[$target] = $true
        foreach ($prefix in @(Assert-Field $extract 'include' "$name.extract")) {
            if ([string]$prefix -ne "*") { [void](Assert-RelativePath ([string]$prefix) "Manifest '$name' include") }
        }
        [void](Assert-Field $extract 'exclude' "$name.extract")
        foreach ($rename in @(Assert-Field $extract 'rename' "$name.extract")) {
            [void](Assert-RelativePath ([string](Assert-Field $rename 'from' "$name.rename")) "Manifest '$name' rename")
            [void](Assert-RelativePath ([string](Assert-Field $rename 'to' "$name.rename")) "Manifest '$name' rename")
        }
        foreach ($required in @(Assert-Field $extract 'required' "$name.extract")) {
            [void](Assert-RelativePath ([string]$required) "Manifest '$name' required")
        }
        foreach ($license in @(Assert-Field $item 'licenses' $name)) {
            [void](Assert-RelativePath ([string]$license) "Manifest '$name' licenses")
        }
    }
    return $items
}

function Test-Archive {
    # True when the file has exactly the pinned size and SHA-256.
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Item
    )
    $actualSize = (Get-Item -LiteralPath $Path).Length
    if ($actualSize -ne [int64]$Item.size) {
        Write-Host "    size $actualSize, expected $($Item.size)" -ForegroundColor Yellow
        return $false
    }
    $stream = [System.IO.File]::OpenRead($Path)
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    try { $actualSha = ([BitConverter]::ToString($hasher.ComputeHash($stream))).Replace('-', '').ToLowerInvariant() }
    finally { $hasher.Dispose(); $stream.Dispose() }
    if ($actualSha -ne $Item.sha256) {
        Write-Host "    sha256 $actualSha, expected $($Item.sha256)" -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Get-VerifiedArchive {
    # Returns the cache path of an archive whose size and hash match the
    # manifest, downloading it when needed. A file only gets its final name
    # after it has been verified.
    param([Parameter(Mandatory = $true)]$Item)

    $final = Join-Path $cacheDir $Item.file
    if (Test-Path -LiteralPath $final -PathType Leaf) {
        Write-Host "    cached: $($Item.file)"
        if (Test-Archive -Path $final -Item $Item) {
            return $final
        }
        throw "Cached archive '$final' does not match the manifest; it was preserved."
    }
    if ($Offline) {
        throw "Archive '$($Item.file)' is missing from the cache or did not match, and -Offline was given."
    }

    $partial = Join-Path $cacheDir ("{0}.partial-{1}" -f $Item.file, [System.Guid]::NewGuid().ToString('N'))
    Write-Host "    downloading $($Item.url)"
    try {
        $handler = New-Object System.Net.Http.HttpClientHandler
        $handler.AllowAutoRedirect = $false
        $client = New-Object System.Net.Http.HttpClient($handler)
        $cancel = New-Object System.Threading.CancellationTokenSource
        $cancel.CancelAfter([TimeSpan]::FromMinutes(15))
        try {
            $response = $client.GetAsync([string]$Item.url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead, $cancel.Token).GetAwaiter().GetResult()
            try {
                if (-not $response.IsSuccessStatusCode) { throw "Download failed with HTTP $([int]$response.StatusCode); redirects are not followed." }
                if ($null -ne $response.Content.Headers.ContentLength -and $response.Content.Headers.ContentLength -ne [int64]$Item.size) { throw 'Download Content-Length does not match manifest.' }
                $inputStream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
                $outputStream = [System.IO.File]::Open($partial, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
                try {
                    $buffer = New-Object byte[] 65536
                    [int64]$total = 0
                    while (($count = $inputStream.ReadAsync($buffer, 0, $buffer.Length, $cancel.Token).GetAwaiter().GetResult()) -gt 0) {
                        $total += $count
                        if ($total -gt [int64]$Item.size) { throw 'Download exceeds pinned size.' }
                        $outputStream.Write($buffer, 0, $count)
                    }
                } finally { $outputStream.Dispose(); $inputStream.Dispose() }
            } finally { $response.Dispose() }
        } finally { $cancel.Dispose(); $client.Dispose(); $handler.Dispose() }
        if (-not (Test-Archive -Path $partial -Item $Item)) {
            throw "Downloaded '$($Item.file)' does not match the pinned size or sha256; nothing was unpacked."
        }
        [System.IO.File]::Move($partial, $final)
    }
    finally {
        if (Test-Path -LiteralPath $partial) {
            Remove-Item -LiteralPath $partial -Force
        }
    }
    return $final
}

function Get-ArchivePlan {
    # Maps archive entries to destination paths. Every entry is checked
    # before anything is written, so a hostile archive fails as a whole.
    param(
        [Parameter(Mandatory = $true)][System.IO.Compression.ZipArchive]$Archive,
        [Parameter(Mandatory = $true)]$Item,
        [Parameter(Mandatory = $true)][string]$TargetDir
    )

    $extract = $Item.extract
    $root = ([string]$extract.root).Replace('\', '/').Trim('/')
    $rootPrefix = if ($root) { "$root/" } else { '' }
    $includes = @($extract.include | ForEach-Object { ([string]$_).Replace('\', '/').Trim('/') })
    $excludes = @($extract.exclude | ForEach-Object { ([string]$_).Replace('\', '/') })
    $renames = @{}
    foreach ($rename in @($extract.rename)) {
        $renames[([string]$rename.from).Replace('\', '/')] = ([string]$rename.to).Replace('\', '/')
    }
    $targetFull = [System.IO.Path]::GetFullPath($TargetDir).TrimEnd('\') + '\'

    $plan = New-Object System.Collections.Generic.List[object]
    $seen = @{}
    $directories = @{}
    foreach ($entry in $Archive.Entries) {
        $name = $entry.FullName.Replace('\', '/')
        [void](Assert-RelativePath $name "Archive '$($Item.file)' entry")
        if (($entry.ExternalAttributes -band 0xF0000000) -eq 0xA0000000) { throw "Archive '$($Item.file)': symbolic link '$name'." }
        if ($name.StartsWith('/') -or $name.Contains(':') -or
            ($name.Split('/') | Where-Object { $_ -eq '..' })) {
            throw "Archive '$($Item.file)': unsafe entry '$($entry.FullName)'."
        }
        if ($name.EndsWith('/')) {
            continue
        }
        if (-not $name.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        $relative = $name.Substring($rootPrefix.Length)

        $included = $false
        foreach ($prefix in $includes) {
            if ($prefix -eq '*' -or $relative -like "$prefix/*" -or $relative -eq $prefix) {
                $included = $true
                break
            }
        }
        if (-not $included) {
            continue
        }
        $excluded = $false
        foreach ($pattern in $excludes) {
            if ($relative -like $pattern) {
                $excluded = $true
                break
            }
        }
        if ($excluded) {
            continue
        }
        if ($renames.ContainsKey($relative)) {
            $relative = $renames[$relative]
        }

        $destination = [System.IO.Path]::GetFullPath((Join-Path $targetFull $relative.Replace('/', '\')))
        if (-not $destination.StartsWith($targetFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Archive '$($Item.file)': entry '$($entry.FullName)' escapes the target folder."
        }
        $key = $destination.ToLowerInvariant()
        if ($directories.ContainsKey($key)) { throw "Archive '$($Item.file)': file/directory collision at '$relative'." }
        $parentKey = [System.IO.Path]::GetDirectoryName($key)
        while ($parentKey -and $parentKey.StartsWith($targetFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            if ($seen.ContainsKey($parentKey)) { throw "Archive '$($Item.file)': file/directory collision at '$relative'." }
            $directories[$parentKey] = $true
            $parentKey = [System.IO.Path]::GetDirectoryName($parentKey)
        }
        if ($seen.ContainsKey($key)) {
            throw "Archive '$($Item.file)': two entries map to '$relative'."
        }
        $seen[$key] = $true
        $plan.Add([pscustomobject]@{ Entry = $entry; Destination = $destination; Relative = $relative })
    }
    return , $plan
}

function Expand-Runtime {
    param(
        [Parameter(Mandatory = $true)]$Item,
        [Parameter(Mandatory = $true)][string]$ArchivePath,
        [Parameter(Mandatory = $true)][string]$StageDir
    )

    $targetDir = Join-Path $StageDir ([string]$Item.extract.target).Replace('/', '\')
    $licenseDir = Join-Path $StageDir ("licenses\{0}" -f $Item.name)
    $root = ([string]$Item.extract.root).Replace('\', '/').Trim('/')
    $rootPrefix = if ($root) { "$root/" } else { '' }

    $archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $plan = Get-ArchivePlan -Archive $archive -Item $Item -TargetDir $targetDir
        if ($plan.Count -eq 0) {
            throw "Archive '$($Item.file)': nothing matched the extract rules."
        }
        foreach ($required in @($Item.extract.required)) {
            if (-not @($plan | Where-Object { ($_.Relative -ieq [string]$required) -or $_.Relative.StartsWith(([string]$required + '/'), [System.StringComparison]::OrdinalIgnoreCase) }).Count) {
                throw "Archive '$($Item.file)': required entry '$required' is missing."
            }
        }
        foreach ($step in $plan) {
            $parent = Split-Path -Parent $step.Destination
            [void][System.IO.Directory]::CreateDirectory($parent)
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($step.Entry, $step.Destination, $false)
            if ($Item.extract.PSObject.Properties.Name -contains 'sha256') {
                $expected = $Item.extract.sha256.PSObject.Properties[$step.Relative]
                $fileStream = [System.IO.File]::OpenRead($step.Destination)
                $hasher = [System.Security.Cryptography.SHA256]::Create()
                try { $actualHash = ([BitConverter]::ToString($hasher.ComputeHash($fileStream))).Replace('-', '').ToLowerInvariant() }
                finally { $hasher.Dispose(); $fileStream.Dispose() }
                if (-not $expected -or $actualHash -ine $expected.Value) {
                    throw "Archive '$($Item.file)': unexpected SHA-256 for '$($step.Relative)'."
                }
            }
        }
        Write-Host ("    unpacked {0} files into {1}" -f $plan.Count, $Item.extract.target)

        [void][System.IO.Directory]::CreateDirectory($licenseDir)
        foreach ($license in @($Item.licenses)) {
            $entryName = $rootPrefix + ([string]$license).Replace('\', '/')
            $entry = $archive.Entries |
                Where-Object { $_.FullName.Replace('\', '/') -ieq $entryName } |
                Select-Object -First 1
            if (-not $entry) {
                throw "Archive '$($Item.file)': license file '$license' not found."
            }
            $leaf = Split-Path -Leaf $entryName.Replace('/', '\')
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $licenseDir $leaf), $false)
        }
    }
    finally {
        $archive.Dispose()
    }

    foreach ($required in @($Item.extract.required)) {
        $path = Join-Path $targetDir ([string]$required).Replace('/', '\')
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Runtime '$($Item.name)': required path '$required' is missing after unpacking."
        }
    }
}

function Assert-InsideBuild {
    # Guards every recursive delete: the path must sit inside build/ and must
    # not be a link that points elsewhere.
    param([Parameter(Mandatory = $true)][string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    $buildFull = [System.IO.Path]::GetFullPath($buildDir).TrimEnd('\') + '\'
    if (-not $full.StartsWith($buildFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to touch '$full': it is outside '$buildFull'."
    }
    if (Test-Path -LiteralPath $full) {
        $attributes = (Get-Item -LiteralPath $full -Force).Attributes
        if ($attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            throw "Refusing to touch '$full': it is a link."
        }
    }
}

if ([System.Net.ServicePointManager]::SecurityProtocol -ne [System.Net.SecurityProtocolType]::SystemDefault) {
    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
}

Write-Step "Reading $Manifest"
$items = Read-Manifest -Path $Manifest

foreach ($ancestor in @((Join-Path $repoRoot 'cache'), (Join-Path $repoRoot 'cache\build'), $cacheDir, $buildDir)) {
    if ((Test-Path -LiteralPath $ancestor) -and ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        throw "Refusing to use linked build/cache directory '$ancestor'."
    }
}

Write-Step 'Verifying archives in the build cache'
[void][System.IO.Directory]::CreateDirectory($cacheDir)
$archives = @{}
foreach ($item in $items) {
    Write-Host ("  {0} {1}" -f $item.name, $item.version)
    $archives[$item.name] = Get-VerifiedArchive -Item $item
}

[void][System.IO.Directory]::CreateDirectory($buildDir)
$stageDir = Join-Path $buildDir ('.staging-' + [System.Guid]::NewGuid().ToString('N'))
Assert-InsideBuild -Path $stageDir
try {
    Write-Step 'Unpacking runtimes'
    [void][System.IO.Directory]::CreateDirectory($stageDir)
    foreach ($item in $items) {
        Write-Host ("  {0}" -f $item.name)
        Expand-Runtime -Item $item -ArchivePath $archives[$item.name] -StageDir $stageDir
    }

    Write-Step 'Adding the Windows UI'
    if (Test-Path -LiteralPath (Join-Path $uiReleaseDir 'Djarvis.exe') -PathType Leaf) {
        foreach ($child in Get-ChildItem -LiteralPath $uiReleaseDir -Force) {
            if (@('runtime', 'licenses') -contains $child.Name) {
                throw "UI release contains '$($child.Name)', which clashes with the runtime layout."
            }
            Copy-Item -LiteralPath $child.FullName -Destination $stageDir -Recurse -Force
        }
        Write-Host "    copied from $uiReleaseDir"
    }
    else {
        Write-Host "    skipped: no UI release at $uiReleaseDir (run scripts/check.ps1 -Build first)" -ForegroundColor Yellow
    }

    Write-Step "Replacing $appDir"
    Assert-InsideBuild -Path $appDir
    $backupDir = $null
    if (Test-Path -LiteralPath $appDir) {
        $backupDir = Join-Path $buildDir ('.app-backup-' + [System.Guid]::NewGuid().ToString('N'))
        Assert-InsideBuild -Path $backupDir
        [System.IO.Directory]::Move($appDir, $backupDir)
    }
    try {
        [System.IO.Directory]::Move($stageDir, $appDir)
    }
    catch {
        if ($backupDir -and -not (Test-Path -LiteralPath $appDir)) {
            [System.IO.Directory]::Move($backupDir, $appDir)
        }
        throw
    }
    if ($backupDir) { Write-Host "Previous application folder preserved at $backupDir" }
}
finally {
    if (Test-Path -LiteralPath $stageDir) {
        Assert-InsideBuild -Path $stageDir
        Remove-Item -LiteralPath $stageDir -Recurse -Force
    }
}

Write-Host "Application folder ready: $appDir" -ForegroundColor Green
