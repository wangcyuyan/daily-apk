# daily-apk 一键编译脚本
# 双击运行或在 PowerShell 中执行此脚本
# 前提：已安装 Android Studio（D:\tesk）+ JDK 17+

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  daily-apk APK 一键编译" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ---- 1. 设置环境变量 ----
$env:ANDROID_HOME = "C:\Users\lenovo\.android-sdk"
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.1"
$sdk = $env:ANDROID_HOME
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$apkShell = Join-Path $projectDir "apk-shell"

Write-Host "[1/5] 环境变量" -ForegroundColor Yellow
Write-Host "  ANDROID_HOME = $sdk"
Write-Host "  JAVA_HOME    = $env:JAVA_HOME"
Write-Host "  项目目录     = $projectDir"

# ---- 2. 检查 / 安装 SDK 组件 ----
Write-Host ""
Write-Host "[2/5] 检查 SDK 组件..." -ForegroundColor Yellow
$platformsDir = Join-Path $sdk "platforms\android-34"
$buildToolsDir = Join-Path $sdk "build-tools\34.0.0"
$mgr = Join-Path $sdk "cmdline-tools\latest\bin\sdkmanager.bat"

if (-not (Test-Path $platformsDir) -or -not (Test-Path $buildToolsDir)) {
    Write-Host "  缺少 platforms 或 build-tools，正在下载安装..." -ForegroundColor Red
    Write-Host "  这一步需要联网，可能需要几分钟..."
    & cmd /c "echo y | `"$mgr`" --sdk_root=`"$sdk`" `"platforms;android-34`" `"build-tools;34.0.0`""
} else {
    Write-Host "  SDK 组件已就绪" -ForegroundColor Green
}

# ---- 3. 用 Gradle 编译 ----
Write-Host ""
Write-Host "[3/5] 编译 APK..." -ForegroundColor Yellow
Set-Location $apkShell

# 检查 gradlew 是否存在
$gradlew = Join-Path $apkShell "gradlew.bat"
if (-not (Test-Path $gradlew)) {
    Write-Host "  未找到 gradlew.bat，尝试用 Android Studio 的 Gradle..." -ForegroundColor Red
    # 尝试找 gradle
    $gradleExe = Get-ChildItem "D:\tesk\plugins\gradle" -Recurse -Filter "gradle.bat" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($gradleExe) {
        Write-Host "  找到 Gradle: $($gradleExe.FullName)"
        & "$($gradleExe.FullName)" -p $apkShell assembleDebug --no-daemon
    } else {
        Write-Host "  未找到 Gradle，请直接用 Android Studio 打开项目编译。" -ForegroundColor Red
        Write-Host "  步骤：打开 Android Studio -> Open -> 选择 $apkShell -> Build -> Build APK(s)"
        pause
        exit 1
    }
} else {
    # 用项目自带的 gradlew
    Write-Host "  使用 gradlew 编译..."
    & $gradlew assembleDebug --no-daemon 2>&1
}

# ---- 4. 找到生成的 APK ----
Write-Host ""
Write-Host "[4/5] 定位 APK 文件..." -ForegroundColor Yellow
$apkFile = Get-ChildItem $apkShell -Recurse -Filter "*.apk" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "intermediates" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($apkFile) {
    Write-Host "" 
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  APK 编译成功！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  文件位置: $($apkFile.FullName)" -ForegroundColor White
    Write-Host "  文件大小: $([math]::Round($apkFile.Length / 1KB, 1)) KB" -ForegroundColor White
    Write-Host ""
    Write-Host "  下一步：把这个 .apk 文件传到手机上安装即可" -ForegroundColor Cyan
    
    # 复制到项目根目录方便找
    Copy-Item $apkFile.FullName (Join-Path $projectDir "daily-app.apk") -Force
    Write-Host "  已复制到: $projectDir\daily-app.apk" -ForegroundColor Cyan
    
    # 自动打开文件夹
    Explorer.exe (Split-Path $apkFile.FullName)
} else {
    Write-Host "  未找到 APK 文件。请检查编译日志中的错误信息。" -ForegroundColor Red
}

# ---- 5. 完成 ----
Write-Host ""
Write-Host "[5/5] 完成！按任意键退出..." -ForegroundColor Green
pause
