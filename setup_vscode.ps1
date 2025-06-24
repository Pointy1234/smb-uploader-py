# PowerShell скрипт настройки VS Code для SMB3 File Processor

param(
    [switch]$CreateWorkspace = $false,
    [switch]$InstallExtensions = $false
)

Write-Host "🎯 Настройка VS Code для SMB3 File Processor" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan

# Проверка VS Code
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    Write-Host "❌ VS Code не найден в PATH!" -ForegroundColor Red
    Write-Host "   Установите VS Code и добавьте в PATH, или запустите из папки VS Code" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ VS Code найден" -ForegroundColor Green

# Создание директории .vscode
$vscodeDir = ".vscode"
if (-not (Test-Path $vscodeDir)) {
    New-Item -ItemType Directory -Force -Path $vscodeDir | Out-Null
    Write-Host "📁 Создана директория .vscode" -ForegroundColor Cyan
}

# Создание launch.json (конфигурация отладки)
Write-Host "🐛 Создание конфигурации отладки..." -ForegroundColor Yellow

$launchConfig = @'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "🚀 SMB3 File Processor",
            "type": "python",
            "request": "launch",
            "program": "app.py",
            "console": "integratedTerminal",
            "env": {
                "FLASK_ENV": "development",
                "FLASK_DEBUG": "1"
            },
            "args": [],
            "python": "python"
        },
        {
            "name": "🧪 Test SMB3 Connection",
            "type": "python",
            "request": "launch",
            "program": "test_smb3.py",
            "console": "integratedTerminal",
            "python": "python"
        },
        {
            "name": "🔍 Test Local API",
            "type": "python",
            "request": "launch",
            "program": "test_local.py",
            "console": "integratedTerminal",
            "python": "python"
        },
        {
            "name": "📦 Prepare Offline",
            "type": "python",
            "request": "launch",
            "program": "prepare_offline.py",
            "console": "integratedTerminal",
            "python": "python"
        }
    ]
}
'@

$launchConfig | Out-File -FilePath (Join-Path $vscodeDir "launch.json") -Encoding UTF8

# Создание tasks.json (задачи)
Write-Host "⚙️ Создание задач VS Code..." -ForegroundColor Yellow

$tasksConfig = @'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "🚀 Start SMB3 Processor",
            "type": "shell",
            "command": "python",
            "args": ["app.py"],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "new",
                "showReuseMessage": true,
                "clear": false
            },
            "problemMatcher": []
        },
        {
            "label": "🧪 Test SMB3 Connection",
            "type": "shell",
            "command": "python",
            "args": ["test_smb3.py"],
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": true,
                "panel": "new"
            }
        },
        {
            "label": "🔍 Test API Endpoints",
            "type": "shell",
            "command": "python",
            "args": ["test_local.py"],
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": true,
                "panel": "new"
            }
        },
        {
            "label": "🐳 Docker Compose Up",
            "type": "shell",
            "command": "docker-compose",
            "args": ["up", "--build", "-d"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "new"
            }
        },
        {
            "label": "🐳 Docker Compose Up (Offline)",
            "type": "shell",
            "command": "docker-compose",
            "args": ["-f", "docker-compose.offline.yml", "up", "--build", "-d"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "new"
            }
        },
        {
            "label": "🛑 Docker Compose Down",
            "type": "shell",
            "command": "docker-compose",
            "args": ["down"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "new"
            }
        },
        {
            "label": "📊 Docker Logs",
            "type": "shell",
            "command": "docker-compose",
            "args": ["logs", "-f", "smb-processor"],
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": true,
                "panel": "new"
            }
        },
        {
            "label": "📦 Install Dependencies",
            "type": "shell",
            "command": "pip",
            "args": ["install", "-r", "requirements.txt"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "new"
            }
        },
        {
            "label": "📋 Setup Environment",
            "type": "shell",
            "command": "powershell",
            "args": ["-Command", "Copy-Item .env.example .env; notepad .env"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "new"
            }
        },
        {
            "label": "🏥 Health Check",
            "type": "shell",
            "command": "powershell",
            "args": ["-Command", "Invoke-RestMethod http://localhost:3000/health"],
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": true,
                "panel": "new"
            }
        }
    ]
}
'@

$tasksConfig | Out-File -FilePath (Join-Path $vscodeDir "tasks.json") -Encoding UTF8

# Создание settings.json (настройки)
Write-Host "⚙️ Создание настроек VS Code..." -ForegroundColor Yellow

$settingsConfig = @'
{
    "python.defaultInterpreterPath": "python",
    "python.terminal.activateEnvironment": true,
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black",
    "python.testing.pytestEnabled": false,
    "python.testing.unittestEnabled": true,
    "files.associations": {
        "docker-compose*.yml": "dockercompose",
        "*.env*": "dotenv",
        "Dockerfile*": "dockerfile"
    },
    "files.exclude": {
        "**/__pycache__": true,
        "**/*.pyc": true,
        "**/offline_packages": true,
        "**/docker_images": true
    },
    "terminal.integrated.defaultProfile.windows": "PowerShell",
    "terminal.integrated.profiles.windows": {
        "PowerShell": {
            "source": "PowerShell",
            "icon": "terminal-powershell"
        },
        "Command Prompt": {
            "path": [
                "${env:windir}\\Sysnative\\cmd.exe",
                "${env:windir}\\System32\\cmd.exe"
            ],
            "args": [],
            "icon": "terminal-cmd"
        }
    },
    "workbench.colorCustomizations": {
        "terminal.background": "#1e1e1e",
        "terminal.foreground": "#d4d4d4"
    },
    "editor.rulers": [88],
    "editor.formatOnSave": true,
    "json.format.enable": true
}
'@

$settingsConfig | Out-File -FilePath (Join-Path $vscodeDir "settings.json") -Encoding UTF8

# Создание extensions.json (рекомендуемые расширения)
Write-Host "🧩 Создание списка расширений..." -ForegroundColor Yellow

$extensionsConfig = @'
{
    "recommendations": [
        "ms-python.python",
        "ms-vscode.vscode-docker",
        "ms-vscode.powershell",
        "humao.rest-client",
        "redhat.vscode-yaml",
        "ms-python.flake8",
        "ms-python.black-formatter",
        "eamodio.gitlens",
        "streetsidesoftware.code-spell-checker",
        "ms-vscode.vscode-json",
        "mikestead.dotenv"
    ]
}
'@

$extensionsConfig | Out-File -FilePath (Join-Path $vscodeDir "extensions.json") -Encoding UTF8

# Создание test.http файла для REST Client
Write-Host "🌐 Создание файла для тестирования API..." -ForegroundColor Yellow

$httpTests = @'
### SMB3 File Processor API Tests
### Используйте расширение REST Client для запуска

### Health Check
GET http://localhost:3000/health
Content-Type: application/json

###

### Process Files
GET http://localhost:3000/process
Content-Type: application/json

###

### Health Check (подробный)
GET http://localhost:3000/health
Accept: application/json
User-Agent: VS Code REST Client

###

### Process Files (с таймаутом)
GET http://localhost:3000/process
Content-Type: application/json
Connection: keep-alive

###
'@

$httpTests | Out-File -FilePath "api_tests.http" -Encoding UTF8

# Создание workspace файла
if ($CreateWorkspace) {
    Write-Host "🏢 Создание workspace файла..." -ForegroundColor Yellow
    
    $workspaceConfig = @'
{
    "folders": [
        {
            "name": "SMB3 File Processor",
            "path": "."
        }
    ],
    "settings": {
        "python.defaultInterpreterPath": "python",
        "terminal.integrated.defaultProfile.windows": "PowerShell"
    },
    "extensions": {
        "recommendations": [
            "ms-python.python",
            "ms-vscode.vscode-docker",
            "ms-vscode.powershell",
            "humao.rest-client"
        ]
    },
    "tasks": {
        "version": "2.0.0",
        "tasks": []
    }
}
'@
    
    $workspaceConfig | Out-File -FilePath "smb3-processor.code-workspace" -Encoding UTF8
}

# Установка расширений
if ($InstallExtensions) {
    Write-Host "🧩 Установка рекомендуемых расширений..." -ForegroundColor Yellow
    
    $extensions = @(
        "ms-python.python",
        "ms-vscode.vscode-docker", 
        "ms-vscode.powershell",
        "humao.rest-client",
        "redhat.vscode-yaml",
        "mikestead.dotenv"
    )
    
    foreach ($extension in $extensions) {
        Write-Host "   Установка $extension..." -ForegroundColor Gray
        try {
            code --install-extension $extension --force
        }
        catch {
            Write-Host "   ⚠️ Не удалось установить $extension" -ForegroundColor Yellow
        }
    }
}

# Создание батч файлов для быстрого запуска
Write-Host "🚀 Создание файлов быстрого запуска..." -ForegroundColor Yellow

# start_vscode.bat
$startVSCode = @'
@echo off
REM Быстрый запуск VS Code с проектом SMB3 File Processor

echo 🚀 Запуск VS Code для SMB3 File Processor
echo ==========================================

REM Проверка VS Code
where code >nul 2>nul
if errorlevel 1 (
    echo ❌ VS Code не найден в PATH!
    echo    Запустите из папки VS Code или добавьте в PATH
    pause
    exit /b
)

REM Проверка .env файла
if not exist .env (
    echo 📋 Создание .env из шаблона...
    copy .env.example .env
    echo ⚠️ Настройте параметры SMB3 в .env
)

REM Запуск VS Code
echo 🎯 Открытие проекта в VS Code...
code .

echo ✅ VS Code запущен!
echo 📋 Полезные команды в VS Code:
echo    Ctrl + Shift + P - Командная палитра
echo    Ctrl + Shift + ` - Новый терминал
echo    F5 - Запуск отладки
echo    Ctrl + R - Запуск задачи
'@

$startVSCode | Out-File -FilePath "start_vscode.bat" -Encoding ASCII

# quick_test.bat
$quickTest = @'
@echo off
REM Быстрое тестирование SMB3 File Processor

echo 🧪 Быстрое тестирование SMB3 File Processor
echo ===========================================

REM Проверка Python
python --version >nul 2>nul
if errorlevel 1 (
    echo ❌ Python не найден!
    pause
    exit /b
)

REM Проверка .env
if not exist .env (
    echo ❌ Файл .env не найден!
    echo    Скопируйте .env.example в .env и настройте
    pause
    exit /b
)

REM Тест SMB3 подключения
echo 🔌 Тестирование SMB3 подключения...
python test_smb3.py
if errorlevel 1 (
    echo ❌ Ошибка подключения к SMB3!
    pause
    exit /b
)

REM Запуск приложения для быстрого теста
echo 🚀 Запуск приложения...
start /b python app.py

REM Ожидание запуска
timeout /t 5 /nobreak >nul

REM Health check
echo 🏥 Проверка health endpoint...
powershell -Command "try { $result = Invoke-RestMethod http://localhost:3000/health; Write-Host '✅ Health check: OK' -ForegroundColor Green; $result } catch { Write-Host '❌ Health check failed' -ForegroundColor Red }"

echo 🎉 Быстрое тестирование завершено!
echo 🌐 Сервис работает на: http://localhost:3000
pause
'@

$quickTest | Out-File -FilePath "quick_test.bat" -Encoding ASCII

Write-Host ""
Write-Host "✅ Настройка VS Code завершена!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Созданные файлы:" -ForegroundColor Cyan
Write-Host "   .vscode/launch.json     - Конфигурация отладки" -ForegroundColor White
Write-Host "   .vscode/tasks.json      - Задачи VS Code" -ForegroundColor White  
Write-Host "   .vscode/settings.json   - Настройки проекта" -ForegroundColor White
Write-Host "   .vscode/extensions.json - Рекомендуемые расширения" -ForegroundColor White
Write-Host "   api_tests.http          - Тесты API для REST Client" -ForegroundColor White
Write-Host "   start_vscode.bat        - Быстрый запуск VS Code" -ForegroundColor White
Write-Host "   quick_test.bat          - Быстрое тестирование" -ForegroundColor White

if ($CreateWorkspace) {
    Write-Host "   smb3-processor.code-workspace - Workspace файл" -ForegroundColor White
}

Write-Host ""
Write-Host "🚀 Следующие шаги:" -ForegroundColor Yellow
Write-Host "1. Запустите: start_vscode.bat" -ForegroundColor White
Write-Host "2. В VS Code нажмите Ctrl + Shift + P" -ForegroundColor White
Write-Host "3. Выберите 'Extensions: Show Recommended Extensions'" -ForegroundColor White
Write-Host "4. Установите рекомендуемые расширения" -ForegroundColor White
Write-Host "5. Нажмите F5 для запуска отладки" -ForegroundColor White
Write-Host ""
Write-Host "🧩 Полезные команды VS Code:" -ForegroundColor Cyan
Write-Host "   F5                  - Запуск отладки" -ForegroundColor White
Write-Host "   Ctrl + Shift + P    - Командная палитра" -ForegroundColor White
Write-Host "   Ctrl + Shift + `    - Новый терминал" -ForegroundColor White
Write-Host "   Ctrl + R            - Запуск задачи" -ForegroundColor White
