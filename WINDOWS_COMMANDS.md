# 🪟 Команды для Windows + Visual Studio Code

## 🚀 БЫСТРЫЙ СТАРТ В VS CODE

### 1. Подготовка рабочей среды
```powershell
# Открыть PowerShell в VS Code (Ctrl + Shift + `)
# Клонировать или распаковать проект
cd C:\path\to\smb3-processor

# Открыть в VS Code
code .
```

### 2. Настройка конфигурации
```powershell
# В терминале VS Code
Copy-Item .env.example .env
notepad .env  # или используйте редактор VS Code
```

**Пример .env для Windows:**
```env
SMB_HOST=192.168.1.100
SMB_SHARE=shared_folder
SMB_USERNAME=domain\username
SMB_PASSWORD=password123
SMB_DOMAIN=CORPORATE
API_URL=http://api-server:8080/api/process
SMB_INPUT_DIR=input
SMB_OUTPUT_DIR=output
```

### 3. Установка зависимостей в VS Code
```powershell
# В терминале VS Code
python -m pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Тестирование в VS Code
```powershell
# Тест SMB3 подключения
python test_smb3.py

# Если успешно, запуск приложения
python app.py
```

## 🔒 АВТОНОМНАЯ УСТАНОВКА (БЕЗ ИНТЕРНЕТА)

### Шаг A: Подготовка на машине с интернетом

#### PowerShell команды:
```powershell
# Полная подготовка offline пакетов
PowerShell -ExecutionPolicy Bypass -File prepare_offline_windows.ps1

# Только Python пакеты (без Docker)
PowerShell -ExecutionPolicy Bypass -File prepare_offline_windows.ps1 -SkipDocker

# Результат: smb3-processor-windows-offline.zip
```

#### В VS Code:
1. **Ctrl + Shift + P** → "Terminal: Create New Terminal"
2. Выполнить команды выше
3. **Ctrl + Shift + E** → найти созданный архив

### Шаг B: Установка на Windows машине без интернета

```powershell
# Распаковать архив
Expand-Archive -Path smb3-processor-windows-offline.zip -DestinationPath C:\smb3-processor
cd C:\smb3-processor

# Открыть в VS Code
code .

# Установка offline пакетов
PowerShell -ExecutionPolicy Bypass -File scripts\install_offline_windows.ps1

# Или быстрый запуск
scripts\start_smb3_windows.bat
```

## 🧪 ТЕСТИРОВАНИЕ В VS CODE

### 1. Встроенный терминал VS Code
```powershell
# Ctrl + Shift + ` (открыть терминал)

# Health check
Invoke-RestMethod http://localhost:3000/health

# Тест обработки файлов
Invoke-RestMethod http://localhost:3000/process

# Полный тест
python test_local.py
```

### 2. Диагностика SMB3 в Windows
```powershell
# Проверка сетевой доступности
Test-NetConnection -ComputerName 192.168.1.100 -Port 445

# Тест SMB3 подключения
python test_smb3.py

# Проверка через net use (Windows)
net use \\192.168.1.100\shared_folder /user:domain\username

# Просмотр активных SMB соединений
Get-SmbConnection
```

### 3. Тестирование через REST Client в VS Code
Создайте файл `test.http` в VS Code:
```http
### Health Check
GET http://localhost:3000/health

### Process Files
GET http://localhost:3000/process
```

## 🐳 DOCKER В WINDOWS + VS CODE

### 1. Docker Desktop для Windows
```powershell
# Проверка Docker
docker --version
docker-compose --version

# Запуск контейнера (с интернетом)
docker-compose up --build -d

# Запуск offline версии
docker-compose -f docker-compose.offline.yml up --build -d
```

### 2. Docker интеграция в VS Code
1. Установить расширение **Docker** в VS Code
2. **Ctrl + Shift + P** → "Docker: Show Logs"
3. **F1** → "Docker Compose Up" для запуска

### 3. Мониторинг в VS Code
```powershell
# Просмотр логов
docker-compose logs -f smb-processor

# Статус контейнеров
docker ps

# Вход в контейнер
docker exec -it smb-file-processor-offline powershell
```

## 📊 ОТЛАДКА В VS CODE

### 1. Конфигурация отладки (.vscode/launch.json)
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: SMB3 App",
            "type": "python",
            "request": "launch",
            "program": "app.py",
            "console": "integratedTerminal",
            "env": {
                "FLASK_ENV": "development",
                "FLASK_DEBUG": "1"
            }
        },
        {
            "name": "Python: Test SMB3",
            "type": "python",
            "request": "launch",
            "program": "test_smb3.py",
            "console": "integratedTerminal"
        }
    ]
}
```

### 2. Задачи VS Code (.vscode/tasks.json)
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Start SMB3 Processor",
            "type": "shell",
            "command": "python",
            "args": ["app.py"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "new"
            }
        },
        {
            "label": "Test SMB3 Connection",
            "type": "shell",
            "command": "python",
            "args": ["test_smb3.py"],
            "group": "test"
        },
        {
            "label": "Docker Compose Up",
            "type": "shell",
            "command": "docker-compose",
            "args": ["up", "--build", "-d"],
            "group": "build"
        }
    ]
}
```

### 3. Настройки VS Code (.vscode/settings.json)
```json
{
    "python.defaultInterpreterPath": "python",
    "python.terminal.activateEnvironment": true,
    "files.associations": {
        "docker-compose*.yml": "dockercompose"
    },
    "python.testing.pytestEnabled": false,
    "python.testing.unittestEnabled": true,
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true
}
```

## 🛠️ УПРАВЛЕНИЕ ЧЕРЕЗ VS CODE

### 1. Команды VS Code (Ctrl + Shift + P)
- **"Tasks: Run Task"** → выбрать задачу
- **"Python: Run Python File in Terminal"** (F5)
- **"Docker: Compose Up"**
- **"Terminal: Create New Terminal"**

### 2. Горячие клавиши
- **F5** - Запуск отладки
- **Ctrl + F5** - Запуск без отладки  
- **Ctrl + Shift + `** - Новый терминал
- **Ctrl + Shift + P** - Командная палитра

### 3. PowerShell команды управления
```powershell
# Остановка
docker-compose down

# Перезапуск
docker-compose restart

# Просмотр статуса
docker-compose ps

# Очистка
docker system prune -f
```

## 🔧 УСТРАНЕНИЕ НЕПОЛАДОК В WINDOWS

### 1. PowerShell права выполнения
```powershell
# Проверка политики выполнения
Get-ExecutionPolicy

# Временное разрешение
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Запуск конкретного скрипта
PowerShell -ExecutionPolicy Bypass -File script.ps1
```

### 2. Python проблемы
```powershell
# Проверка Python
python --version
where python

# Обновление pip
python -m pip install --upgrade pip

# Переустановка зависимостей
pip uninstall -r requirements.txt -y
pip install -r requirements.txt
```

### 3. Docker проблемы в Windows
```powershell
# Перезапуск Docker Desktop
Restart-Service docker

# Проверка WSL2 (для Docker Desktop)
wsl --list --verbose

# Очистка Docker
docker system prune -a -f
```

### 4. SMB проблемы в Windows
```powershell
# Проверка SMB клиента
Get-WindowsFeature -Name FS-SMB1 | Select InstallState
Get-SmbClientConfiguration

# Включение SMB3
Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol-Client -All

# Тест подключения
Test-NetConnection -ComputerName 192.168.1.100 -Port 445 -InformationLevel Detailed
```

## ⚡ БЫСТРЫЕ КОМАНДЫ ДЛЯ VS CODE

### Терминал VS Code (PowerShell)
```powershell
# Полный цикл тестирования
Copy-Item .env.example .env; notepad .env; python test_smb3.py; docker-compose up --build -d; Start-Sleep 10; Invoke-RestMethod http://localhost:3000/health

# Offline установка и тест
PowerShell -ExecutionPolicy Bypass -File scripts\install_offline_windows.ps1; python test_smb3.py; docker-compose -f docker-compose.offline.yml up -d
```

### Создание ярлыков в VS Code
1. **File** → **Preferences** → **Keyboard Shortcuts**
2. Поиск "Tasks: Run Task" → назначить **Ctrl + R**
3. Поиск "Python: Run Python File" → назначить **F5**

## 📋 ПОЛЕЗНЫЕ РАСШИРЕНИЯ VS CODE

Рекомендуемые расширения:
- **Python** (Microsoft)
- **Docker** (Microsoft)  
- **PowerShell** (Microsoft)
- **REST Client** (Huachao Mao)
- **YAML** (Red Hat)
- **GitLens** (GitKraken)

Установка через VS Code:
**Ctrl + Shift + X** → поиск → Install

## 🎯 КОНТРОЛЬНЫЙ СПИСОК ДЛЯ WINDOWS

### Предварительные требования:
- [ ] Windows 10/11 с PowerShell 5.0+
- [ ] Python 3.7+ установлен и в PATH
- [ ] Docker Desktop for Windows установлен
- [ ] Visual Studio Code установлен
- [ ] Доступ к SMB3 серверу

### Проверка готовности:
```powershell
# Проверить все компоненты
python --version; docker --version; Get-ExecutionPolicy; Test-NetConnection 192.168.1.100 -Port 445
```

### После установки:
- [ ] **Invoke-RestMethod http://localhost:3000/health** возвращает healthy
- [ ] **docker ps** показывает запущенный контейнер
- [ ] **python test_smb3.py** проходит успешно
- [ ] Логи не содержат ошибок
- [ ] Файлы обрабатываются корректно

## 🆘 ЭКСТРЕННЫЕ КОМАНДЫ

```powershell
# Полная очистка и перезапуск
docker-compose down; docker system prune -f; docker-compose up --build -d

# Сброс Python окружения
pip freeze | ForEach-Object { pip uninstall $_.Split('==')[0] -y }; pip install -r requirements.txt

# Перезапуск Docker Desktop
Restart-Service docker; Start-Sleep 30; docker version
```
