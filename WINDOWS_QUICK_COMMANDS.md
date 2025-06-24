# ⚡ Быстрые команды для Windows

## 🚀 МГНОВЕННЫЙ ЗАПУСК

### Интерактивное меню (рекомендуется)
```cmd
start_windows.bat
```

### VS Code
```cmd
start_vscode.bat
code .
```

### Быстрое тестирование
```cmd
quick_test.bat
```

## 📋 ОСНОВНЫЕ КОМАНДЫ

### PowerShell команды:
```powershell
# Настройка конфигурации
Copy-Item .env.example .env
notepad .env

# Тест SMB3
python test_smb3.py

# Запуск Docker
docker-compose up --build -d

# Проверка работы
Invoke-RestMethod http://localhost:3000/health
Invoke-RestMethod http://localhost:3000/process

# Просмотр логов
docker-compose logs -f smb-processor

# Остановка
docker-compose down
```

### CMD команды:
```cmd
REM Настройка
copy .env.example .env
notepad .env

REM Тест SMB3
python test_smb3.py

REM Запуск приложения локально
python app.py

REM Проверка здоровья
powershell -Command "Invoke-RestMethod http://localhost:3000/health"
```

## 🔒 OFFLINE РЕЖИМ

### Подготовка (на машине с интернетом):
```powershell
PowerShell -ExecutionPolicy Bypass -File prepare_offline_windows.ps1
```

### Установка (на машине без интернета):
```powershell
PowerShell -ExecutionPolicy Bypass -File scripts\install_offline_windows.ps1
docker-compose -f docker-compose.offline.yml up -d
```

## 🧪 ТЕСТИРОВАНИЕ

```powershell
# Проверка всех компонентов
python --version; docker --version; Test-NetConnection 192.168.1.100 -Port 445

# Health check
Invoke-RestMethod http://localhost:3000/health

# Полный тест API
python test_local.py

# Диагностика SMB3
python test_smb3.py
```

## 🛠️ УПРАВЛЕНИЕ DOCKER

```powershell
# Статус
docker-compose ps

# Логи
docker-compose logs -f smb-processor

# Перезапуск
docker-compose restart

# Полная пересборка
docker-compose down; docker-compose up --build -d

# Очистка
docker system prune -f
```

## 🔧 ДИАГНОСТИКА

```powershell
# Проверка SMB3 сервера
Test-NetConnection 192.168.1.100 -Port 445

# Проверка процессов
Get-Process | Where-Object {$_.ProcessName -like "*python*"}
Get-Process | Where-Object {$_.ProcessName -like "*docker*"}

# Проверка портов
netstat -an | Select-String ":3000"

# Проверка Docker
docker ps -a
docker images
```

## 📂 VS CODE ГОРЯЧИЕ КЛАВИШИ

- **F5** - Запуск отладки
- **Ctrl + F5** - Запуск без отладки
- **Ctrl + Shift + `** - Новый терминал
- **Ctrl + Shift + P** - Командная палитра
- **Ctrl + R** - Запуск задачи

## 🆘 ЭКСТРЕННЫЕ КОМАНДЫ

```powershell
# Полная очистка и перезапуск
docker-compose down
docker system prune -a -f
docker-compose up --build -d

# Сброс Python окружения
pip freeze | ForEach-Object { pip uninstall $_.Split('==')[0] -y }
pip install -r requirements.txt

# Перезапуск Docker Desktop
Restart-Service docker
```

## ⚙️ ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ

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

## 🎯 КОНТРОЛЬНЫЕ ТОЧКИ

### Успешный запуск:
- [ ] `python test_smb3.py` - OK
- [ ] `docker-compose ps` - Up
- [ ] `Invoke-RestMethod http://localhost:3000/health` - healthy
- [ ] Логи без ошибок
- [ ] Файлы обрабатываются

### При ошибках:
1. Проверить .env файл
2. Тестировать SMB3 подключение  
3. Проверить Docker статус
4. Просмотреть логи
5. Проверить сетевую доступность
