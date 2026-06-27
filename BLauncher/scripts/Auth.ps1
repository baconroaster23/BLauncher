

param(
    [string]$ConfigPath = "$PSScriptRoot\..\config.json"
)

$ErrorActionPreference = "Stop"

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$clientId = $config.client_id
if (-not $clientId -or $clientId -eq "PUT-YOUR-AZURE-CLIENT-ID-HERE") {
    Write-Error "No Azure client_id set in config.json. See README.md for how to register one (it's free)."
    exit 1
}

$dataDir = Join-Path $PSScriptRoot "..\data"
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
$cachePath   = Join-Path $dataDir "auth-cache.json"
$sessionPath = Join-Path $dataDir "session.json"

function Get-MinecraftProfile($mcAccessToken) {
    $headers = @{ Authorization = "Bearer $mcAccessToken" }
    return Invoke-RestMethod -Uri "https://api.minecraftservices.com/minecraft/profile" -Headers $headers
}

function Get-MinecraftToken($msAccessToken) {
    $xblBody = @{
        Properties   = @{
            AuthMethod = "RPS"
            SiteName   = "user.auth.xboxlive.com"
            RpsTicket  = "d=$msAccessToken"
        }
        RelyingParty = "http://auth.xboxlive.com"
        TokenType    = "JWT"
    } | ConvertTo-Json -Depth 5

    $xbl = Invoke-RestMethod -Uri "https://user.auth.xboxlive.com/user/authenticate" -Method Post -Body $xblBody -ContentType "application/json"
    $xblToken = $xbl.Token
    $uhs = $xbl.DisplayClaims.xui[0].uhs

    $xstsBody = @{
        Properties   = @{
            SandboxId  = "RETAIL"
            UserTokens = @($xblToken)
        }
        RelyingParty = "rp://api.minecraftservices.com/"
        TokenType    = "JWT"
    } | ConvertTo-Json -Depth 5

    $xsts = Invoke-RestMethod -Uri "https://xsts.auth.xboxlive.com/xsts/authorize" -Method Post -Body $xstsBody -ContentType "application/json"

    $mcBody = @{ identityToken = "XBL3.0 x=$uhs;$($xsts.Token)" } | ConvertTo-Json
    $mc = Invoke-RestMethod -Uri "https://api.minecraftservices.com/authentication/login_with_xbox" -Method Post -Body $mcBody -ContentType "application/json"
    return $mc.access_token
}

function New-DeviceCodeLogin {
    $dc = Invoke-RestMethod -Uri "https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode" -Method Post -Body @{
        client_id = $clientId
        scope     = "XboxLive.signin offline_access"
    }

    Write-Host ""
    Write-Host "=================================================="
    Write-Host " Open:        $($dc.verification_uri)"
    Write-Host " Enter code:  $($dc.user_code)"
    Write-Host "=================================================="
    Write-Host "Waiting for you to finish logging in..."

    $interval = $dc.interval
    $expires  = (Get-Date).AddSeconds($dc.expires_in)

    while ((Get-Date) -lt $expires) {
        Start-Sleep -Seconds $interval
        try {
            return Invoke-RestMethod -Uri "https://login.microsoftonline.com/consumers/oauth2/v2.0/token" -Method Post -Body @{
                grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
                client_id   = $clientId
                device_code = $dc.device_code
            }
        } catch {
            $err = $null
            try { $err = $_.ErrorDetails.Message | ConvertFrom-Json } catch {}
            switch ($err.error) {
                "authorization_pending" { continue }
                "authorization_declined" { Write-Error "Login was declined."; exit 1 }
                "expired_token" { Write-Error "Login code expired - run again."; exit 1 }
                default { Write-Error "Auth error: $($err.error)"; exit 1 }
            }
        }
    }
    Write-Error "Login timed out."
    exit 1
}

function Update-MsToken($refreshToken) {
    return Invoke-RestMethod -Uri "https://login.microsoftonline.com/consumers/oauth2/v2.0/token" -Method Post -Body @{
        grant_type    = "refresh_token"
        client_id     = $clientId
        refresh_token = $refreshToken
        scope         = "XboxLive.signin offline_access"
    }
}

$msToken = $null
if (Test-Path $cachePath) {
    $cache = Get-Content $cachePath -Raw | ConvertFrom-Json
    try {
        Write-Host "Refreshing existing login..."
        $msToken = Update-MsToken $cache.refresh_token
    } catch {
        Write-Host "Cached login expired - signing in again."
    }
}

if (-not $msToken) {
    $msToken = New-DeviceCodeLogin
}

$msToken | ConvertTo-Json | Out-File $cachePath -Encoding utf8

$mcAccessToken = Get-MinecraftToken $msToken.access_token
$profile = Get-MinecraftProfile $mcAccessToken

[ordered]@{
    access_token = $mcAccessToken
    uuid         = $profile.id
    username     = $profile.name
} | ConvertTo-Json | Out-File $sessionPath -Encoding utf8

Write-Host "[++] Logged in as $($profile.name)"
