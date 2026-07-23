[CmdletBinding()]
param(
    [string] $GodotBin,
    [switch] $Export,
    [ValidateSet('All', 'WindowsDebug', 'WindowsRelease', 'AndroidRelease')]
    [string] $ExportTarget = 'All'
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
        throw "Release verification failed at '$Name' with exit code $LASTEXITCODE."
    }
}

function Invoke-GodotExport {
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Mode,

        [Parameter(Mandatory)]
        [string] $Preset,

        [Parameter(Mandatory)]
        [string] $OutputPath
    )

    $outputDirectory = Split-Path -Parent $OutputPath
    if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
    }

    Invoke-GodotStep -Name $Name -Arguments @(
        '--headless', '--path', $projectRoot,
        $Mode, $Preset, $OutputPath
    )
}

function Invoke-AndroidReleaseExport {
    param(
        [Parameter(Mandatory)]
        [string] $OutputPath
    )

    if ([string]::IsNullOrWhiteSpace($env:GODOT_ANDROID_RELEASE_KEYSTORE) -or
        [string]::IsNullOrWhiteSpace($env:GODOT_ANDROID_RELEASE_USER) -or
        [string]::IsNullOrWhiteSpace($env:GODOT_ANDROID_RELEASE_PASSWORD)) {
        throw "Android release export requires GODOT_ANDROID_RELEASE_KEYSTORE, GODOT_ANDROID_RELEASE_USER, and GODOT_ANDROID_RELEASE_PASSWORD. export_presets.cfg intentionally commits blank keystore fields."
    }

    $presetPath = Join-Path $projectRoot 'export_presets.cfg'
    $originalPreset = Get-Content -LiteralPath $presetPath -Raw
    $injectedPreset = $originalPreset `
        -replace 'keystore/release=""', ('keystore/release="{0}"' -f ($env:GODOT_ANDROID_RELEASE_KEYSTORE -replace '\\', '/')) `
        -replace 'keystore/release_user=""', ('keystore/release_user="{0}"' -f $env:GODOT_ANDROID_RELEASE_USER) `
        -replace 'keystore/release_password=""', ('keystore/release_password="{0}"' -f $env:GODOT_ANDROID_RELEASE_PASSWORD)

    try {
        Set-Content -LiteralPath $presetPath -Value $injectedPreset -NoNewline
        Invoke-GodotExport `
            -Name 'export Android Release' `
            -Mode '--export-release' `
            -Preset 'Android Release' `
            -OutputPath $OutputPath
    } finally {
        Set-Content -LiteralPath $presetPath -Value $originalPreset -NoNewline
    }
}

Invoke-GodotStep -Name 'release content contract' -Arguments @(
    '--headless', '--path', $projectRoot,
    '--script', 'tools/validate_content.gd'
)
Invoke-GodotStep -Name 'editor import / preset load' -Arguments @(
    '--headless', '--path', $projectRoot, '--import'
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

if ($Export) {
    $windowsDebug = Join-Path $projectRoot 'build/windows/debug/godot-ai-project-a-debug.exe'
    $windowsRelease = Join-Path $projectRoot 'build/windows/release/godot-ai-project-a.exe'
    $androidRelease = Join-Path $projectRoot 'build/android/project-a-release.apk'

    if ($ExportTarget -in @('All', 'WindowsDebug')) {
        Invoke-GodotExport `
            -Name 'export Windows Desktop Debug' `
            -Mode '--export-debug' `
            -Preset 'Windows Desktop Debug' `
            -OutputPath $windowsDebug
    }
    if ($ExportTarget -in @('All', 'WindowsRelease')) {
        Invoke-GodotExport `
            -Name 'export Windows Desktop Release' `
            -Mode '--export-release' `
            -Preset 'Windows Desktop Release' `
            -OutputPath $windowsRelease
    }
    if ($ExportTarget -in @('All', 'AndroidRelease')) {
        Invoke-AndroidReleaseExport -OutputPath $androidRelease
    }
}

Write-Host 'Full release verification passed.'
