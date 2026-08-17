$ErrorActionPreference = "Continue"

Write-Host "=== daily-apk build script ==="

$env:ANDROID_HOME = "C:\Users\lenovo\.android-sdk"
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.1"
$sdk = $env:ANDROID_HOME
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$apkShell = Join-Path $projectDir "apk-shell"

Write-Host "ANDROID_HOME = $sdk"
Write-Host "JAVA_HOME    = $env:JAVA_HOME"

# Step 1: create license file (skip interactive prompt)
$licDir = Join-Path $sdk "licenses"
if (-not (Test-Path $licDir)) { New-Item -ItemType Directory -Path $licDir -Force | Out-Null }
$licFile = Join-Path $licDir "android-sdk-license"
if (-not (Test-Path $licFile)) { Set-Content -Path $licFile -Value "24333f8a63b6825ea9c5514f83c2829b004d1fee" -NoNewline }
Write-Host "License file ready"

# Step 2: install missing SDK components if needed
$platformsDir = Join-Path $sdk "platforms\android-34"
$buildToolsDir = Join-Path $sdk "build-tools\34.0.0"
$mgr = Join-Path $sdk "cmdline-tools\latest\bin\sdkmanager.bat"

if ((-not (Test-Path $platformsDir)) -or (-not (Test-Path $buildToolsDir))) {
    Write-Host "Installing SDK components (this may take a few minutes)..."
    & cmd /c "echo y | `"$mgr`" --sdk_root=`"$sdk`" `"platforms;android-34`" `"build-tools;34.0.0`""
} else {
    Write-Host "SDK components already present"
}

# Step 3: build APK with gradlew
Set-Location $apkShell
$gradlew = Join-Path $apkShell "gradlew.bat"
Write-Host "Building APK with gradlew..."
& $gradlew assembleDebug --no-daemon

# Step 4: locate the generated APK
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
