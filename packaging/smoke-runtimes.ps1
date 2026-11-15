<#
.SYNOPSIS
    Checks that the bundled runtimes in an assembled application folder start
    without any system-wide Python or PostgreSQL.

.DESCRIPTION
    Runs each check with PATH reduced to the Windows system folder and with
    Python and PostgreSQL environment variables removed, so only files inside
    the application folder can be picked up:
        djarvis-core.exe -I -c "import sys; print(sys.version)"
        postgres --version, initdb --version, pg_ctl --version
    Versions must match packaging/runtimes.json. No cluster is created and no
    server is started. Checks that the required Visual C++ runtime DLLs are
    present, and verifies the PostgreSQL copies against the pinned hashes.
    Works in Windows PowerShell 5.1 and PowerShell 7.

.PARAMETER AppDir
    Assembled application folder. Defaults to build/app.

.PARAMETER Manifest
    Runtime manifest with the expected versions. Defaults to
    packaging/runtimes.json.
#>
[CmdletBinding()]
param(
    [string]$AppDir,
    [string]$Manifest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
if (-not $AppDir) {
    $AppDir = Join-Path $repoRoot 'build\app'
}
if (-not $Manifest) {
    $Manifest = Join-Path $PSScriptRoot 'runtimes.json'
}
$AppDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($AppDir)
if (-not (Test-Path -LiteralPath $AppDir -PathType Container)) {
    throw "Application folder not found: '$AppDir'. Run packaging/build-app.ps1 first."
}

$runtimes = @{}
foreach ($item in (Get-Content -LiteralPath $Manifest -Raw -Encoding UTF8 | ConvertFrom-Json).runtimes) {
    $runtimes[[string]$item.name] = $item
}
foreach ($name in @('python', 'postgresql', 'vc-crt')) {
    if (-not $runtimes.ContainsKey($name)) {
        throw "Manifest has no '$name' runtime."
    }
}

$systemDir = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::System)
$workDir = Join-Path ([System.IO.Path]::GetTempPath()) ('djarvis-smoke-' + [System.Guid]::NewGuid().ToString('N'))
$failures = New-Object System.Collections.Generic.List[string]

function Invoke-Isolated {
    # Starts a program with a minimal environment and returns its exit code
    # and output. The working folder is an empty temporary folder.
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$Arguments
    )

    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $FilePath
    $info.Arguments = $Arguments
    $info.WorkingDirectory = $workDir
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true

    $environment = $info.EnvironmentVariables
    $environment['PATH'] = $systemDir
    foreach ($key in @($environment.Keys)) {
        if ($key -match '^(PYTHON|PG)' -or $key -ieq 'VIRTUAL_ENV' -or $key -ieq 'CONDA_PREFIX') {
            $environment.Remove($key)
        }
    }

    $process = [System.Diagnostics.Process]::Start($info)
    try {
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        if (-not $process.WaitForExit(60000)) {
            $process.Kill()
            throw "'$FilePath' did not finish within 60 seconds."
        }
        $process.WaitForExit()
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Output   = $stdoutTask.Result.Trim()
            Error    = $stderrTask.Result.Trim()
        }
    }
    finally {
        $process.Dispose()
    }
}

function Test-Command {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$Arguments,
        [Parameter(Mandatory = $true)][string]$ExpectedPattern
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        $failures.Add("${Label}: '$FilePath' is missing")
        Write-Host "FAIL $Label - file missing" -ForegroundColor Red
        return
    }
    $result = Invoke-Isolated -FilePath $FilePath -Arguments $Arguments
    $shown = if ($result.Output) { $result.Output } else { $result.Error }
    if ($result.ExitCode -ne 0) {
        $failures.Add("${Label}: exit code $($result.ExitCode)")
        Write-Host "FAIL $Label (exit $($result.ExitCode)): $shown" -ForegroundColor Red
    }
    elseif ($result.Output -notmatch $ExpectedPattern) {
        $failures.Add("${Label}: unexpected output '$($result.Output)'")
        Write-Host "FAIL $Label - unexpected output: $shown" -ForegroundColor Red
    }
    else {
        Write-Host "ok   $Label (exit 0): $($result.Output)" -ForegroundColor Green
    }
}

function Write-CrtReport {
    # Requires the Visual C++ runtime DLLs in the application folder.
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$Folder,
        [Parameter(Mandatory = $true)][string[]]$Needed
    )

    foreach ($dll in $Needed) {
        if (Test-Path -LiteralPath (Join-Path $Folder $dll) -PathType Leaf) {
            Write-Host "ok   $Label ships $dll"
        }
        else {
            $failures.Add("${Label}: $dll is missing")
            Write-Host "FAIL $Label - $dll is missing" -ForegroundColor Red
        }
    }
}

$pythonDir = Join-Path $AppDir 'runtime\python'
$pgBin = Join-Path $AppDir 'runtime\pgsql\bin'
$pythonVersion = [regex]::Escape([string]$runtimes['python'].version)
$pgVersion = [regex]::Escape([string]$runtimes['postgresql'].version)

# Verify every executable and required CRT before starting any runtime process.
Write-Host '==> Checking required runtime files' -ForegroundColor Cyan
foreach ($path in @(
    (Join-Path $pythonDir 'djarvis-core.exe'),
    (Join-Path $pgBin 'postgres.exe'),
    (Join-Path $pgBin 'initdb.exe'),
    (Join-Path $pgBin 'pg_ctl.exe')
)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $failures.Add("Required executable missing: $path")
        Write-Host "FAIL required executable missing: $path" -ForegroundColor Red
    }
}
Write-CrtReport 'python' $pythonDir @('vcruntime140.dll', 'vcruntime140_1.dll')
Write-CrtReport 'pgsql/bin' $pgBin @('vcruntime140.dll', 'vcruntime140_1.dll', 'msvcp140.dll')
foreach ($dll in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
    $path = Join-Path $pgBin $dll
    $expected = $runtimes['vc-crt'].extract.sha256.PSObject.Properties[$dll]
    $actualHash = $null
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $stream = [System.IO.File]::OpenRead($path)
        $hasher = [System.Security.Cryptography.SHA256]::Create()
        try { $actualHash = ([BitConverter]::ToString($hasher.ComputeHash($stream))).Replace('-', '').ToLowerInvariant() }
        finally { $hasher.Dispose(); $stream.Dispose() }
    }
    if (-not $expected -or $actualHash -ine $expected.Value) {
        $failures.Add("pgsql/bin: $dll missing or SHA-256 mismatch")
        Write-Host "FAIL pgsql/bin - $dll missing or SHA-256 mismatch" -ForegroundColor Red
    }
}
if ($failures.Count -gt 0) {
    Write-Host ("Smoke test failed before launch: {0}" -f ($failures -join '; ')) -ForegroundColor Red
    exit 1
}

[void][System.IO.Directory]::CreateDirectory($workDir)
try {
    Write-Host "==> Smoke test of $AppDir (PATH=$systemDir)" -ForegroundColor Cyan
    Test-Command 'djarvis-core -I sys.version' (Join-Path $pythonDir 'djarvis-core.exe') '-I -c "import sys; print(sys.version)"' "^$pythonVersion "
    Test-Command 'postgres --version' (Join-Path $pgBin 'postgres.exe') '--version' "^postgres \(PostgreSQL\) $pgVersion$"
    Test-Command 'initdb --version' (Join-Path $pgBin 'initdb.exe') '--version' "^initdb \(PostgreSQL\) $pgVersion$"
    Test-Command 'pg_ctl --version' (Join-Path $pgBin 'pg_ctl.exe') '--version' "^pg_ctl \(PostgreSQL\) $pgVersion$"
}
finally {
    Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    Write-Host ("Smoke test failed: {0}" -f ($failures -join '; ')) -ForegroundColor Red
    exit 1
}
Write-Host 'Smoke test passed.' -ForegroundColor Green
