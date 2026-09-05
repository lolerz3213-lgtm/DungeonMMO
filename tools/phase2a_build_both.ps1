$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$DungeonProject = Join-Path $ProjectRoot "default.project.json"
$BaseProject = Join-Path $ProjectRoot "base.project.json"
$OutputRoot = Join-Path $env:TEMP "DungeonMMO_Phase2A_TEST"
$DungeonOutput = Join-Path $OutputRoot "DungeonMMO_Phase2A_Dungeon.rbxl"
$BaseOutput = Join-Path $OutputRoot "DungeonMMO_Phase2A_Base.rbxl"

function Invoke-RojoBuild {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )

    & rojo build $ProjectFile -o $OutputFile
    if ($LASTEXITCODE -ne 0) {
        throw "Rojo build failed: $ProjectFile"
    }
    if (-not (Test-Path -LiteralPath $OutputFile -PathType Leaf)) {
        throw "Rojo did not create: $OutputFile"
    }
}

function Main {
    <#
    .SYNOPSIS
        Builds both Phase 2A Roblox Places for TEST validation.

    .DESCRIPTION
        Creates clean Dungeon and Base RBXL validation builds in the
        temporary directory without modifying the normal Studio place file.

    .OUTPUTS
        System.String. Prints the two generated validation file paths.
    #>
    New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

    Invoke-RojoBuild `
        -ProjectFile $DungeonProject `
        -OutputFile $DungeonOutput
    Invoke-RojoBuild `
        -ProjectFile $BaseProject `
        -OutputFile $BaseOutput

    Write-Host ""
    Write-Host "Phase 2A TEST validation builds created." `
        -ForegroundColor Green
    Write-Host "Dungeon: $DungeonOutput"
    Write-Host "Base:    $BaseOutput"
}

Main
