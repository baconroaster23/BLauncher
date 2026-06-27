
param(
    [Parameter(Mandatory = $true)][string]$VersionId,
    [Parameter(Mandatory = $true)][string]$RootDir,
    [string]$JavaPath = "java",
    [switch]$Offline,
    [string]$Username
)

$ErrorActionPreference = "Stop"

$versionDir = Join-Path $RootDir "versions\$VersionId"
$state = Get-Content (Join-Path $versionDir "state.json") -Raw | ConvertFrom-Json
$versionJson = Get-Content $state.VersionJsonPath -Raw | ConvertFrom-Json


function Get-OfflineUUID([string]$Name) {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("OfflinePlayer:$Name"))
    $bytes[6] = ($bytes[6] -band 0x0f) -bor 0x30   # version 3
    $bytes[8] = ($bytes[8] -band 0x3f) -bor 0x80   # variant
    $hex = ($bytes | ForEach-Object { $_.ToString("x2") }) -join ""
    return "$($hex.Substring(0,8))-$($hex.Substring(8,4))-$($hex.Substring(12,4))-$($hex.Substring(16,4))-$($hex.Substring(20,12))"
}

$userType = "msa"
if ($Offline) {
    if (-not $Username) { Write-Error "Offline mode needs -Username."; exit 1 }
    $session = [pscustomobject]@{
        username     = $Username
        uuid         = Get-OfflineUUID $Username
        access_token = "0"
    }
    $userType = "legacy"
} else {
    $sessionPath = "$PSScriptRoot\..\data\session.json"
    if (-not (Test-Path $sessionPath)) {
        Write-Error "No session found - run Auth.ps1 first, or pass -Offline -Username <name>."
        exit 1
    }
    $session = Get-Content $sessionPath -Raw | ConvertFrom-Json
}

$classpath = ($state.ClasspathEntries -join ";")
$mainClass = $versionJson.mainClass

$replacements = @{
    '${auth_player_name}'  = $session.username
    '${version_name}'      = $VersionId
    '${game_directory}'    = $RootDir
    '${assets_root}'       = (Join-Path $RootDir "assets")
    '${assets_index_name}' = $state.AssetIndexName
    '${auth_uuid}'         = $session.uuid
    '${auth_access_token}' = $session.access_token
    '${auth_session}'      = $session.access_token
    '${user_type}'         = $userType
    '${version_type}'      = $versionJson.type
    '${natives_directory}' = $state.NativesDir
    '${launcher_name}'     = "BatchLauncher"
    '${launcher_version}'  = "1.0"
    '${classpath}'         = $classpath
}


function Expand-ArgList($argList) {
    $out = @()
    foreach ($a in $argList) {
        if ($a -is [string]) {
            $val = $a
            foreach ($key in $replacements.Keys) { $val = $val.Replace($key, [string]$replacements[$key]) }
            $out += $val
        }
    }
    return $out
}

$gameArgs = @()
$jvmArgs  = @("-Xmx2G")

if ($versionJson.arguments) {
    $jvmArgs  += Expand-ArgList $versionJson.arguments.jvm
    $gameArgs += Expand-ArgList $versionJson.arguments.game
} elseif ($versionJson.minecraftArguments) {
    # Legacy (pre-1.13) single-string argument format
    $legacy = $versionJson.minecraftArguments
    foreach ($key in $replacements.Keys) { $legacy = $legacy.Replace($key, [string]$replacements[$key]) }
    $gameArgs += ($legacy -split ' ')
} else {
    Write-Error "Couldn't find launch arguments in the version JSON."
    exit 1
}

$fullArgs = $jvmArgs + @("-cp", $classpath, $mainClass) + $gameArgs

Write-Host "Launching Minecraft $VersionId as $($session.username)..."
& $JavaPath @fullArgs
