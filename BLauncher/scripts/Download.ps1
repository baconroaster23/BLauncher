

param(
    [Parameter(Mandatory = $true)][string]$VersionId,
    [Parameter(Mandatory = $true)][string]$RootDir
)

. "$PSScriptRoot\Common.ps1"

$ErrorActionPreference = "Stop"

$manifestUrl = "https://launchermeta.mojang.com/mc/game/version_manifest_v2.json"
$versionsDir  = Join-Path $RootDir "versions"
$librariesDir = Join-Path $RootDir "libraries"
$assetsDir    = Join-Path $RootDir "assets"
New-Item -ItemType Directory -Force -Path $versionsDir, $librariesDir, $assetsDir | Out-Null

Write-Host "Fetching version manifest..."
$manifest = Invoke-RestMethod -Uri $manifestUrl

$entry = $manifest.versions | Where-Object { $_.id -eq $VersionId }
if (-not $entry) {
    Write-Error "Version '$VersionId' was not found in the manifest. Check the ID and try again."
    exit 1
}

$versionDir = Join-Path $versionsDir $VersionId
New-Item -ItemType Directory -Force -Path $versionDir | Out-Null
$versionJsonPath = Join-Path $versionDir "$VersionId.json"

if (-not (Test-Path $versionJsonPath)) {
    Write-Host "Downloading version JSON..."
    Invoke-WebRequest -Uri $entry.url -OutFile $versionJsonPath
}

$versionJson = Get-Content $versionJsonPath -Raw | ConvertFrom-Json

if (-not $versionJson.downloads -or -not $versionJson.downloads.client) {
    Write-Error "This version's JSON doesn't use the modern download format. Pre-1.13 versions aren't supported by this script yet."
    exit 1
}


$clientJarPath = Join-Path $versionDir "$VersionId.jar"
if (-not (Test-Path $clientJarPath)) {
    Write-Host "Downloading client.jar..."
    Invoke-WebRequest -Uri $versionJson.downloads.client.url -OutFile $clientJarPath
}

$nativesDir = Join-Path $versionDir "natives"
New-Item -ItemType Directory -Force -Path $nativesDir | Out-Null

$classpathEntries = @($clientJarPath)
$osName = Get-OSName

foreach ($lib in $versionJson.libraries) {
    if ($lib.rules -and -not (Test-Rule $lib.rules)) { continue }

    if ($lib.downloads.artifact) {
        $art = $lib.downloads.artifact
        $libPath = Join-Path $librariesDir ($art.path -replace '/', '\')
        New-Item -ItemType Directory -Force -Path (Split-Path $libPath -Parent) | Out-Null
        if (-not (Test-Path $libPath)) {
            Write-Host "Downloading library: $($lib.name)"
            try { Invoke-WebRequest -Uri $art.url -OutFile $libPath }
            catch { Write-Warning "Failed to download library: $($lib.name)" }
        }
        $classpathEntries += $libPath
    }

    if ($lib.downloads.classifiers) {
        $nativeKey = "natives-$osName"
        $classifier = $lib.downloads.classifiers.$nativeKey
        if ($classifier) {
            $nativeJarPath = Join-Path $librariesDir ($classifier.path -replace '/', '\')
            New-Item -ItemType Directory -Force -Path (Split-Path $nativeJarPath -Parent) | Out-Null
            if (-not (Test-Path $nativeJarPath)) {
                Write-Host "Downloading native library: $($lib.name)"
                Invoke-WebRequest -Uri $classifier.url -OutFile $nativeJarPath
            }
            Write-Host "Extracting natives from $($lib.name)..."
            Expand-Archive -Path $nativeJarPath -DestinationPath $nativesDir -Force -ErrorAction SilentlyContinue
        }
    }
}


$assetIndexId = $versionJson.assetIndex.id
$assetIndexPath = Join-Path $assetsDir "indexes\$assetIndexId.json"
New-Item -ItemType Directory -Force -Path (Split-Path $assetIndexPath -Parent) | Out-Null
if (-not (Test-Path $assetIndexPath)) {
    Write-Host "Downloading asset index..."
    Invoke-WebRequest -Uri $versionJson.assetIndex.url -OutFile $assetIndexPath
}
$assetIndex = Get-Content $assetIndexPath -Raw | ConvertFrom-Json

$objectsDir = Join-Path $assetsDir "objects"
New-Item -ItemType Directory -Force -Path $objectsDir | Out-Null

$allProps = @($assetIndex.objects.PSObject.Properties)
$total = $allProps.Count
$i = 0
foreach ($prop in $allProps) {
    $i++
    $hash = $prop.Value.hash
    $sub = $hash.Substring(0, 2)
    $destDir = Join-Path $objectsDir $sub
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    $destPath = Join-Path $destDir $hash
    if (-not (Test-Path $destPath)) {
        Write-Progress -Activity "Downloading assets" -Status "$i / $total ($($prop.Name))" -PercentComplete (($i / $total) * 100)
        try { Invoke-WebRequest -Uri "https://resources.download.minecraft.net/$sub/$hash" -OutFile $destPath }
        catch { Write-Warning "Failed asset: $($prop.Name)" }
    }
}
Write-Progress -Activity "Downloading assets" -Completed


$state = [ordered]@{
    ClasspathEntries = $classpathEntries
    NativesDir       = $nativesDir
    AssetIndexName   = $assetIndexId
    VersionJsonPath  = $versionJsonPath
    GameDir          = $RootDir
}
$state | ConvertTo-Json -Depth 5 | Out-File (Join-Path $versionDir "state.json") -Encoding utf8

Write-Host ""
Write-Host "[++] Download complete for $VersionId"
