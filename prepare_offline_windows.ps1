# PowerShell скрипт подготовки offline пакетов для Windows
# SMB3 File Processor - Подготовка автономного развертывания

param(
    [switch]$SkipDocker = $false,
    [string]$OutputPath = "."
)

Write-Host "🚀 Подготовка offline пакетов SMB3 File Processor для Windows" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan

# Проверка PowerShell версии
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "❌ Требуется PowerShell 5.0 или выше!" -ForegroundColor Red
    exit 1
}

# Проверка Python
Write-Host "🐍 Проверка Python..." -ForegroundColor Yellow
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Python не найден! Установите Python и добавьте в PATH." -ForegroundColor Red
    Write-Host "   Скачать: https://python.org/downloads/" -ForegroundColor White
    exit 1
}

$pythonVersion = python --version 2>&1
Write-Host "✅ Найден: $pythonVersion" -ForegroundColor Green

# Проверка pip
if (-not (Get-Command pip -ErrorAction SilentlyContinue)) {
    Write-Host "❌ pip не найден!" -ForegroundColor Red
    exit 1
}

# Проверка Docker (если не пропускаем)
if (-not $SkipDocker) {
    Write-Host "🐳 Проверка Docker..." -ForegroundColor Yellow
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Docker не найден! Установите Docker Desktop for Windows." -ForegroundColor Red
        Write-Host "   Скачать: https://docker.com/products/docker-desktop" -ForegroundColor White
        exit 1
    }
    
    # Проверка что Docker запущен
    try {
        $dockerVersion = docker version --format "{{.Server.Version}}" 2>$null
        if (-not $dockerVersion) {
            Write-Host "❌ Docker не запущен! Запустите Docker Desktop." -ForegroundColor Red
            exit 1
        }
        Write-Host "✅ Docker работает: $dockerVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Ошибка подключения к Docker!" -ForegroundColor Red
        exit 1
    }
}

# Проверка requirements.txt
if (-not (Test-Path "requirements.txt")) {
    Write-Host "❌ Файл requirements.txt не найден!" -ForegroundColor Red
    exit 1
}

# Создание директорий
Write-Host "📁 Создание директорий..." -ForegroundColor Yellow
$offlineDir = Join-Path $OutputPath "offline_packages"
$dockerDir = Join-Path $OutputPath "docker_images"
$scriptDir = Join-Path $OutputPath "scripts"

@($offlineDir, $dockerDir, $scriptDir) | ForEach-Object {
    if (Test-Path $_) {
        Remove-Item $_ -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $_ | Out-Null
}

# Скачивание Python пакетов
Write-Host "📦 Скачивание Python пакетов..." -ForegroundColor Yellow

try {
    # Обновление pip
    python -m pip install --upgrade pip wheel setuptools
    
    # Скачивание основных пакетов
    python -m pip download --dest $offlineDir -r requirements.txt
    
    # Скачивание дополнительных инструментов
    python -m pip download --dest $offlineDir wheel setuptools pip
    
    $packageCount = (Get-ChildItem $offlineDir -File).Count
    Write-Host "✅ Скачано пакетов: $packageCount" -ForegroundColor Green
}
catch {
    Write-Host "❌ Ошибка скачивания Python пакетов: $_" -ForegroundColor Red
    exit 1
}

# Создание requirements-offline.txt
Write-Host "📄 Создание requirements-offline.txt..." -ForegroundColor Yellow
$offlineRequirements = @"
# Offline requirements для SMB3 File Processor (Windows)
# Установка: pip install --no-index --find-links .\offline_packages -r requirements-offline.txt

# Web framework
Flask==3.0.0
Werkzeug==3.0.1

# SMB3 поддержка
smbprotocol==1.12.0
pyspnego==0.10.2
cryptography>=3.4.8
ntlm-auth>=1.5.0

# HTTP requests
requests==2.31.0

# Environment variables
python-dotenv==1.0.0

# Дополнительные зависимости
six>=1.16.0
urllib3==2.1.0
"@

$offlineRequirements | Out-File -FilePath (Join-Path $offlineDir "requirements-offline.txt") -Encoding UTF8

# Docker образы (если не пропускаем)
if (-not $SkipDocker) {
    Write-Host "🐳 Подготовка Docker образов..." -ForegroundColor Yellow
    
    try {
        # Загрузка базового образа
        Write-Host "   Загрузка python:3.11-slim..." -ForegroundColor Gray
        docker pull python:3.11-slim
        
        # Сборка offline образа
        Write-Host "   Сборка smb3-processor-offline..." -ForegroundColor Gray
        docker build -f Dockerfile.offline -t smb3-processor-offline .
        
        # Сохранение образов
        Write-Host "   Сохранение образов в файлы..." -ForegroundColor Gray
        docker save python:3.11-slim -o (Join-Path $dockerDir "python-3.11-slim.tar")
        docker save smb3-processor-offline -o (Join-Path $dockerDir "smb3-processor-offline.tar")
        
        Write-Host "✅ Docker образы подготовлены" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Ошибка подготовки Docker образов: $_" -ForegroundColor Red
        Write-Host "   Попробуйте запустить с параметром -SkipDocker" -ForegroundColor Yellow
    }
}

# Создание скриптов установки для Windows
Write-Host "📝 Создание скриптов установки..." -ForegroundColor Yellow

# PowerShell скрипт установки
$installScript = @'
# install_offline_windows.ps1 - Установка SMB3 File Processor (Windows offline)

Write-Host "🚀 Установка SMB3 File Processor (Windows offline)" -ForegroundColor Green

# Проверка offline_packages
if (-not (Test-Path "offline_packages")) {
    Write-Host "❌ Директория offline_packages не найдена!" -ForegroundColor Red
    exit 1
}

# Проверка requirements-offline.txt
if (-not (Test-Path "offline_packages\requirements-offline.txt")) {
    Write-Host "❌ Файл requirements-offline.txt не найден!" -ForegroundColor Red
    exit 1
}

Write-Host "📦 Установка Python пакетов из offline архива..." -ForegroundColor Yellow

# Подсчет пакетов
$packageCount = (Get-ChildItem offline_packages -Filter "*.whl","*.tar.gz").Count
Write-Host "📋 Найдено пакетов для установки: $packageCount" -ForegroundColor Cyan

# Установка пакетов
try {
    pip install --no-index --find-links .\offline_packages -r .\offline_packages\requirements-offline.txt
    Write-Host "✅ Python пакеты установлены успешно" -ForegroundColor Green
}
catch {
    Write-Host "❌ Ошибка установки пакетов: $_" -ForegroundColor Red
    exit 1
}

# Проверка установки
Write-Host "🧪 Проверка установки модулей..." -ForegroundColor Yellow
try {
    python -c @"
import flask
import smbprotocol
import requests
import dotenv
print('✅ Все основные модули импортированы успешно')
print(f'   Flask: {flask.__version__}')
print(f'   SMBProtocol: {smbprotocol.__version__}')
print(f'   Requests: {requests.__version__}')
"@
    Write-Host "✅ Проверка модулей прошла успешно" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Предупреждение: Ошибка при проверке модулей" -ForegroundColor Yellow
}

# Загрузка Docker образов (если есть)
if (Test-Path "docker_images") {
    Write-Host "🐳 Загрузка Docker образов..." -ForegroundColor Yellow
    
    $imageFiles = @(
        "docker_images\python-3.11-slim.tar",
        "docker_images\smb3-processor-offline.tar"
    )
    
    foreach ($imageFile in $imageFiles) {
        if (Test-Path $imageFile) {
            Write-Host "   Загрузка $(Split-Path $imageFile -Leaf)..." -ForegroundColor Gray
            docker load -i $imageFile
        }
    }
    Write-Host "✅ Docker образы загружены" -ForegroundColor Green
}

# Настройка конфигурации
if (-not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item .env.example .env
        Write-Host "📋 Создан файл .env из шаблона" -ForegroundColor Cyan
        Write-Host "⚠️ ВАЖНО: Настройте параметры SMB3 в файле .env!" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎉 Offline установка завершена успешно!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Следующие шаги:" -ForegroundColor Cyan
Write-Host "1. Настройте .env файл с параметрами SMB3" -ForegroundColor White
Write-Host "2. Проверьте подключение: python test_smb3.py" -ForegroundColor White
Write-Host "3. Запустите сервис: docker-compose -f docker-compose.offline.yml up -d" -ForegroundColor White
Write-Host "4. Проверьте работу: Invoke-RestMethod http://localhost:3000/health" -ForegroundColor White
'@

$installScript | Out-File -FilePath (Join-Path $scriptDir "install_offline_windows.ps1") -Encoding UTF8

# Batch файл для запуска
$batchScript = @'
@echo off
REM start_smb3_windows.bat - Быстрый запуск SMB3 File Processor

echo 🚀 Запуск SMB3 File Processor для Windows
echo =========================================

REM Проверка .env файла
if not exist .env (
    echo 📋 Создание .env из шаблона...
    copy .env.example .env
    echo ⚠️ Настройте параметры SMB3 в .env и запустите снова
    notepad .env
    pause
    exit /b
)

REM Тест SMB3 подключения
echo 🧪 Тестирование SMB3 подключения...
python test_smb3.py
if errorlevel 1 (
    echo ❌ Ошибка подключения к SMB3!
    pause
    exit /b
)

REM Запуск Docker
echo 🐳 Запуск Docker контейнера...
docker-compose -f docker-compose.offline.yml up -d

REM Ожидание запуска
echo ⏳ Ожидание запуска сервиса...
timeout /t 15 /nobreak

REM Проверка работы
echo 🔍 Проверка работоспособности...
powershell -Command "try { $result = Invoke-RestMethod http://localhost:3000/health; Write-Host '✅ Health check: OK' -ForegroundColor Green; Write-Host $result } catch { Write-Host '❌ Health check failed' -ForegroundColor Red }"

echo 🎉 SMB3 File Processor запущен!
echo 🌐 Сервис доступен: http://localhost:3000
echo 📊 Логи: docker-compose -f docker-compose.offline.yml logs -f
pause
'@

$batchScript | Out-File -FilePath (Join-Path $scriptDir "start_smb3_windows.bat") -Encoding ASCII

# Создание архива
Write-Host "📦 Создание архива для Windows..." -ForegroundColor Yellow

$archiveName = "smb3-processor-windows-offline"
$archivePath = Join-Path $OutputPath "$archiveName.zip"

# Список файлов для архива
$filesToArchive = @(
    "app.py",
    "requirements.txt",
    ".env.example",
    "Dockerfile.offline",
    "docker-compose.offline.yml",
    "test_smb3.py",
    "test_local.py",
    "README_smb_processor.md",
    "WINDOWS_COMMANDS.md",
    "OFFLINE_INSTALL_GUIDE.md",
    "QUICK_START_SMB3.md"
)

# Создание временной директории для архива
$tempArchiveDir = Join-Path $OutputPath "temp_archive"
New-Item -ItemType Directory -Force -Path $tempArchiveDir | Out-Null

# Копирование файлов
foreach ($file in $filesToArchive) {
    if (Test-Path $file) {
        Copy-Item $file $tempArchiveDir
    }
}

# Копирование директорий
Copy-Item $offlineDir (Join-Path $tempArchiveDir "offline_packages") -Recurse
Copy-Item $dockerDir (Join-Path $tempArchiveDir "docker_images") -Recurse
Copy-Item $scriptDir (Join-Path $tempArchiveDir "scripts") -Recurse

# Создание архива
try {
    if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
        Compress-Archive -Path "$tempArchiveDir\*" -DestinationPath $archivePath -Force
        Write-Host "✅ Архив создан: $archivePath" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Compress-Archive недоступен. Файлы подготовлены в: $tempArchiveDir" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "⚠️ Ошибка создания архива: $_" -ForegroundColor Yellow
    Write-Host "   Файлы подготовлены в: $tempArchiveDir" -ForegroundColor White
}

# Очистка временной директории
if (Test-Path $tempArchiveDir) {
    Remove-Item $tempArchiveDir -Recurse -Force
}

# Подсчет размеров
if (Test-Path $archivePath) {
    $archiveSize = [math]::Round((Get-Item $archivePath).Length / 1MB, 1)
    Write-Host "📊 Размер архива: $archiveSize MB" -ForegroundColor Cyan
}

$offlineSize = [math]::Round((Get-ChildItem $offlineDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
$dockerSize = if (Test-Path $dockerDir) { [math]::Round((Get-ChildItem $dockerDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 1) } else { 0 }

Write-Host ""
Write-Host "✅ Подготовка offline пакетов завершена!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Статистика:" -ForegroundColor Cyan
Write-Host "   Python пакеты: $offlineSize MB" -ForegroundColor White
if (-not $SkipDocker) {
    Write-Host "   Docker образы: $dockerSize MB" -ForegroundColor White
}
Write-Host "   Общий размер: $([math]::Round($offlineSize + $dockerSize, 1)) MB" -ForegroundColor White
Write-Host ""
Write-Host "📦 Для передачи на Windows машину без интернета:" -ForegroundColor Yellow
Write-Host "   Архив: $archivePath" -ForegroundColor White
Write-Host ""
Write-Host "📋 Инструкции для целевой Windows машины:" -ForegroundColor Cyan
Write-Host "1. Распакуйте архив" -ForegroundColor White
Write-Host "2. Запустите: PowerShell -ExecutionPolicy Bypass -File scripts\install_offline_windows.ps1" -ForegroundColor White
Write-Host "3. Или используйте: scripts\start_smb3_windows.bat" -ForegroundColor White
Write-Host ""
Write-Host "⚠️ На целевой машине должен быть установлен Docker Desktop!" -ForegroundColor Yellow
