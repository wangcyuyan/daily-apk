$ErrorActionPreference = "Continue"

Write-Host "=== daily-apk build script ==="

# Disable all proxies: Java/Gradle auto-reads the system SOCKS proxy and times out.
# This was the cause of the previous "Connect timed out" failure.
$env:HTTP_PROXY=""
$env:HTTPS_PROXY=""
$env:ALL_PROXY=""
$env:SOCKS_PROXY=""
$env:GRADLE_OPTS = "-Djava.net.useSystemProxies=false -DsocksProxyHost= -Dhttp.proxyHost= -Dhttps.proxyHost= -Dftp.proxyHost="
$env:JAVA_OPTS = "-Djava.net.useSystemProxies=false -DsocksProxyHost= -Dhttp.proxyHost= -Dhttps.proxyHost="

$env:ANDROID_HOME = "C:\Users\lenovo\.android-sdk"
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.1"
$sdk = $env:ANDROID_HOME
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$apkShell = Join-Path $projectDir "apk-shell"

Write-Host "ANDROID_HOME = $sdk"
Write-Host "JAVA_HOME    = $env:JAVA_HOME"

# license
$licDir = Join-Path $sdk "licenses"
if (-not (Test-Path $licDir)) { New-Item -ItemType Directory -Path $licDir -Force | Out-Null }
$licFile = Join-Path $licDir "android-sdk-license"
if (-not (Test-Path $licFile)) { Set-Content -Path $licFile -Value "24333f8a63b6825ea9c5514f83c2829b004d1fee" -NoNewline }

# install sdk
$platformsDir = Join-Path $sdk "platforms\android-34"
$buildToolsDir = Join-Path $sdk "build-tools\34.0.0"
$mgr = Join-Path $sdk "cmdline-tools\latest\bin\sdkmanager.bat"

if ((-not (Test-Path $platformsDir)) -or (-not (Test-Path $buildToolsDir))) {
    Write-Host "Installing SDK components..."
    & cmd /c "echo y | `"$mgr`" --sdk_root=`"$sdk`" `"platforms;android-34`" `"build-tools;34.0.0`""
} else {
    Write-Host "SDK components present"
}

# build
Set-Location $apkShell
$gradlew = Join-Path $apkShell "gradlew.bat"
Write-Host "Building APK with gradlew..."
& $gradlew assembleDebug --no-daemon

# find apk
$apkFile = Get-ChildItem $apkShell -Recurse -Filter "*.apk" |
    Where-Object { $_.FullName -notmatch "intermediates" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($apkFile) {
    Write-Host "BUILD SUCCESS"
    Write-Host "APK location: $($apkFile.FullName)"
    Copy-Item $apkFile.FullName (Join-Path $projectDir "daily-app.apk") -Force
    Write-Host "Copied to: $projectDir\daily-app.apk"
    Start-Process explorer.exe (Split-Path $apkFile.FullName)
} else {
    Write-Host "BUILD FAILED - check the log above"
    Write-Host "Fallback: open Android Studio (D:\tesk\bin\studio64.exe), open $apkShell, click Build -> Build APK(s)"
}
