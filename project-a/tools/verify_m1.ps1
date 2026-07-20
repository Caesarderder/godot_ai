[CmdletBinding()]
param(
    [string] $GodotBin
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $projectRoot '..')).Path

if ([string]::IsNullOrWhiteSpace($GodotBin)) {
    $GodotBin = Join-Path `
        $repositoryRoot `
        '.tools/godot/4.7.1/Godot_v4.7.1-stable_win64_console.exe'
}

if (Test-Path -LiteralPath $GodotBin -PathType Leaf) {
    $GodotBin = (Resolve-Path -LiteralPath $GodotBin).Path
} else {
    $resolvedCommand = Get-Command -Name $GodotBin -CommandType Application -ErrorAction SilentlyContinue
    if ($null -eq $resolvedCommand) {
        throw "Godot executable was not found: $GodotBin"
    }
    $GodotBin = $resolvedCommand.Source
}

function Invoke-GodotStep {
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string[]] $Arguments
    )

    Write-Host "==> $Name"
    & $GodotBin @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "M1 verification failed at '$Name' with exit code $LASTEXITCODE."
    }
}

Invoke-GodotStep -Name 'editor import' -Arguments @(
    '--headless', '--path', $projectRoot, '--editor', '--quit'
)
Invoke-GodotStep -Name 'mobile startup' -Arguments @(
    '--headless', '--path', $projectRoot, '--quit-after', '2'
)
Invoke-GodotStep -Name 'compatibility startup' -Arguments @(
    '--headless', '--path', $projectRoot,
    '--rendering-method', 'gl_compatibility', '--quit-after', '2'
)
Invoke-GodotStep -Name 'complete GUT suite' -Arguments @(
    '--headless', '-d', '--path', $projectRoot,
    '-s', 'addons/gut/gut_cmdln.gd',
    '-gdir=res://tests', '-ginclude_subdirs', '-gexit'
)

Write-Host 'M1 verification passed.'
