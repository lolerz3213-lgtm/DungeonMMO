param(
    [string]$Repo = "C:\Users\Remko\Documents\Roblox\DungeonMMO"
)

$ErrorActionPreference = "Stop"
Set-Location $Repo

$failures = New-Object System.Collections.Generic.List[string]

function Require-Glob(
    [string]$ProjectPath,
    [string]$ExpectedGlob
) {
    $project = Get-Content $ProjectPath -Raw | ConvertFrom-Json
    $globs = @($project.globIgnorePaths)

    if ($globs -notcontains $ExpectedGlob) {
        $failures.Add(
            "$ProjectPath does not exclude $ExpectedGlob"
        )
    }
}

if (-not (Test-Path "published-dungeon.project.json")) {
    $failures.Add(
        "published-dungeon.project.json does not exist"
    )
}

if (-not (Test-Path "published-base.project.json")) {
    $failures.Add(
        "published-base.project.json does not exist"
    )
}

if (Test-Path "published-dungeon.project.json") {
    Require-Glob `
        "published-dungeon.project.json" `
        "**/Tests/**"

    Require-Glob `
        "published-dungeon.project.json" `
        "**/DungeonSliceUi.client.luau"
}

if (Test-Path "published-base.project.json") {
    Require-Glob `
        "published-base.project.json" `
        "**/Tests/**"
}

$feedback = Get-Content `
    "src\StarterPlayerScripts\Combat\FeedbackController.client.luau" `
    -Raw

if ($feedback -match 'Imported clips are\s*"\s*\.\.\s*"Studio-only until published') {
    $failures.Add(
        "FeedbackController still has no published sword-animation path"
    )
}

if (Test-Path "src\StarterPlayerScripts\Dungeon\DungeonSliceUi.client.luau") {
    $failures.Add(
        "legacy DungeonSliceUi is still present in the source tree"
    )
}

if ($failures.Count -eq 0) {
    Write-Host "[Published Composition Check] PASS"
    exit 0
}

Write-Host ""
Write-Host "[Published Composition Check] RED"
foreach ($failure in $failures) {
    Write-Host " - $failure"
}

exit 1
