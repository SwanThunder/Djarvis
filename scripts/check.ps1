<#
.SYNOPSIS
    Runs the repository checks: Python core first, then the Flutter UI.

.DESCRIPTION
    Stops at the first failing step and exits with its code. Works in
    Windows PowerShell 5.1 and PowerShell 7.

.PARAMETER Python
    Python interpreter with core/requirements/dev.txt and the core package
    installed. Accepts a path or a command name (for example "python" in CI).
    Defaults to the local virtual environment core/.venv.

.PARAMETER Build
    Also builds the Windows release of the UI (requires Visual Studio with
    the C++ desktop workload).
#>
[CmdletBinding()]
param(
    [string]$Python,
    [switch]$Build
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$coreDir = Join-Path $repoRoot 'core'
$uiDir = Join-Path $repoRoot 'ui'

if (-not $Python) {
    $Python = Join-Path $coreDir '.venv\Scripts\python.exe'
}
$pythonCommand = Get-Command $Python -CommandType Application -ErrorAction SilentlyContinue |
    Select-Object -First 1
if (-not $pythonCommand) {
    throw "Python interpreter not found: '$Python'. Create core/.venv or pass -Python."
}
$pythonExe = $pythonCommand.Source

function Invoke-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][scriptblock]$Command
    )

    Write-Host "==> $Name" -ForegroundColor Cyan
    Push-Location $WorkingDirectory
    try {
        & $Command
        $code = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
    if ($code -ne 0) {
        Write-Host "FAILED: $Name (exit code $code)" -ForegroundColor Red
        exit $code
    }
}

Invoke-Step 'ruff check' $coreDir { & $pythonExe -m ruff check . }
Invoke-Step 'ruff format --check' $coreDir { & $pythonExe -m ruff format --check . }
Invoke-Step 'mypy --strict' $coreDir { & $pythonExe -m mypy --strict djarvis_core tests }
Invoke-Step 'pytest' $coreDir { & $pythonExe -m pytest }

Invoke-Step 'flutter pub get' $uiDir { & flutter pub get --enforce-lockfile }
Invoke-Step 'dart format' $uiDir { & dart format --output=none --set-exit-if-changed lib test }
Invoke-Step 'flutter analyze' $uiDir { & flutter analyze --fatal-infos --fatal-warnings }
Invoke-Step 'flutter test' $uiDir { & flutter test }

if ($Build) {
    Invoke-Step 'flutter build windows' $uiDir { & flutter build windows --release }
}

Write-Host 'All checks passed.' -ForegroundColor Green
