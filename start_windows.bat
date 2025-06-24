@echo off
REM SMB3 File Processor - Быстрый запуск для Windows
REM Версия: 1.0

title SMB3 File Processor - Windows Launcher

echo.
echo  ███████╗███╗   ███╗██████╗ ██████╗     ███████╗██╗██╗     ███████╗
echo  ██╔════╝████╗ ████║██╔══██╗╚════██╗    ██╔════╝██║██║     ██╔════╝
echo  ███████╗██╔████╔██║██████╔╝ █████╔╝    █████╗  ██║██║     █████╗  
echo  ╚════██║██║╚██╔╝██║██╔══██╗ ╚═══██╗    ██╔══╝  ██║██║     ██╔══╝  
echo  ███████║██║ ╚═╝ ██║██████╔╝██████╔╝    ██║     ██║███████╗███████╗
echo  ╚══════╝╚═╝     ╚═╝╚═════╝ ╚═════╝     ╚═╝     ╚═╝╚══════╝╚══════╝
echo.
echo  ██████╗ ██████╗  ██████╗  ██████╗███████╗███████╗███████╗ ██████╗ ██████╗ 
echo  ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔════╝██╔════╝██╔════╝██╔═══██╗██╔══██╗
echo  ██████╔╝██████╔╝██║   ██║██║     █████╗  ███████╗███████╗██║   ██║██████╔╝
echo  ██╔═══╝ ██╔══██╗██║   ██║██║     ██╔══╝  ╚════██║╚════██║██║   ██║██╔══██╗
echo  ██║     ██║  ██║╚██████╔╝╚██████╗███████╗███████║███████║╚██████╔╝██║  ██║
echo  ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚══════╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
echo.
echo         SMB3 File Processor для Windows - Быстрый запуск
echo         ================================================
echo.

:MENU
echo 📋 Выберите действие:
echo.
echo  1. 🚀 Запуск с Docker (рекомендуется)
echo  2. 🐍 Локальный запуск (Python)
echo  3. 🧪 Тестирование SMB3 подключения
echo  4. ⚙️  Настройка конфигурации (.env)
echo  5. 📊 Просмотр логов Docker
echo  6. 🛑 Остановка сервиса
echo  7. 🔧 Диагностика системы
echo  8. 💻 Открыть в VS Code
echo  9. 📖 Показать документацию
echo  0. ❌ Выход
echo.
set /p choice="Введите номер (0-9): "

if "%choice%"=="1" goto DOCKER_START
if "%choice%"=="2" goto LOCAL_START
if "%choice%"=="3" goto TEST_SMB3
if "%choice%"=="4" goto SETUP_CONFIG
if "%choice%"=="5" goto SHOW_LOGS
if "%choice%"=="6" goto STOP_SERVICE
if "%choice%"=="7" goto DIAGNOSTICS
if "%choice%"=="8" goto OPEN_VSCODE
if "%choice%"=="9" goto SHOW_DOCS
if "%choice%"=="0" goto EXIT
echo Неверный выбор. Попробуйте снова.
pause
goto MENU

:DOCKER_START
echo.
echo 🐳 Запуск с Docker...
echo =====================

REM Проверка Docker
where docker >nul 2>nul
if errorlevel 1 (
    echo ❌ Docker не найден!
    echo    Установите Docker Desktop for Windows
    pause
    goto MENU
)

REM Проверка .env
if not exist .env (
    echo 📋 Создание .env из шаблона...
    if exist .env.example (
        copy .env.example .env
        echo ⚠️  Файл .env создан. Настройте параметры SMB3!
        notepad .env
    ) else (
        echo ❌ Файл .env.example не найден!
        pause
        goto MENU
    )
)

REM Выбор режима
echo.
echo Выберите режим Docker:
echo  1. С интернетом (обычный)
echo  2. Offline режим (без интернета)
set /p docker_choice="Введите 1 или 2: "

if "%docker_choice%"=="1" (
    echo 🔗 Запуск в режиме с интернетом...
    docker-compose up --build -d
) else (
    echo 🔒 Запуск в offline режиме...
    docker-compose -f docker-compose.offline.yml up --build -d
)

if errorlevel 1 (
    echo ❌ Ошибка запуска Docker!
    pause
    goto MENU
)

echo ⏳ Ожидание запуска сервиса...
timeout /t 15 /nobreak >nul

echo 🏥 Проверка работоспособности...
powershell -Command "try { $result = Invoke-RestMethod http://localhost:3000/health -TimeoutSec 10; Write-Host '✅ Сервис запущен успешно!' -ForegroundColor Green; Write-Host ('Статус: ' + $result.status) -ForegroundColor Cyan } catch { Write-Host '⚠️ Сервис недоступен, проверьте логи' -ForegroundColor Yellow }"

echo.
echo 🎉 Docker контейнер запущен!
echo 🌐 Сервис доступен: http://localhost:3000
echo 📊 Для просмотра логов выберите пункт 5 в меню
pause
goto MENU

:LOCAL_START
echo.
echo 🐍 Локальный запуск...
echo =====================

REM Проверка Python
python --version >nul 2>nul
if errorlevel 1 (
    echo ❌ Python не найден!
    echo    Установите Python и добавьте в PATH
    pause
    goto MENU
)

REM Проверка .env
if not exist .env (
    echo 📋 Создание .env из шаблона...
    if exist .env.example (
        copy .env.example .env
        echo ⚠️  Настройте параметры SMB3 в .env!
        notepad .env
    ) else (
        echo ❌ Файл .env.example не найден!
        pause
        goto MENU
    )
)

REM Проверка зависимостей
echo 📦 Проверка Python зависимостей...
pip show flask >nul 2>nul
if errorlevel 1 (
    echo 📥 Установка зависимостей...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo ❌ Ошибка установки зависимостей!
        pause
        goto MENU
    )
)

echo 🚀 Запуск приложения...
echo ⚠️  Для остановки нажмите Ctrl+C
python app.py
pause
goto MENU

:TEST_SMB3
echo.
echo 🧪 Тестирование SMB3 подключения...
echo ===================================

REM Проверка Python
python --version >nul 2>nul
if errorlevel 1 (
    echo ❌ Python не найден!
    pause
    goto MENU
)

REM Проверка .env
if not exist .env (
    echo ❌ Файл .env не найден!
    echo    Сначала настройте конфигурацию (пункт 4)
    pause
    goto MENU
)

REM Проверка test_smb3.py
if not exist test_smb3.py (
    echo ❌ Файл test_smb3.py не найден!
    pause
    goto MENU
)

echo 🔌 Выполнение теста SMB3...
python test_smb3.py
if errorlevel 1 (
    echo.
    echo ❌ Тест SMB3 не прошел!
    echo 🔧 Проверьте:
    echo    - Настройки в .env файле
    echo    - Доступность SMB3 сервера
    echo    - Правильность логина/пароля
    echo    - Включен ли SMB3 на сервере
) else (
    echo.
    echo ✅ Тест SMB3 прошел успешно!
    echo 🎉 SMB3 File Processor готов к работе
)
pause
goto MENU

:SETUP_CONFIG
echo.
echo ⚙️ Настройка конфигурации...
echo =============================

if not exist .env.example (
    echo ❌ Файл .env.example не найден!
    pause
    goto MENU
)

if not exist .env (
    echo 📋 Создание .env из шаблона...
    copy .env.example .env
)

echo 📝 Открытие .env для редактирования...
echo.
echo 💡 Настройте следующие параметры:
echo    SMB_HOST     - IP адрес SMB3 сервера
echo    SMB_SHARE    - Имя SMB3 шары
echo    SMB_USERNAME - Имя пользователя
echo    SMB_PASSWORD - Пароль
echo    SMB_DOMAIN   - Домен (или WORKGROUP)
echo    API_URL      - URL вашего API сервера
echo.
notepad .env
echo ✅ Конфигурация сохранена
pause
goto MENU

:SHOW_LOGS
echo.
echo 📊 Просмотр логов...
echo ====================

REM Проверка Docker
where docker >nul 2>nul
if errorlevel 1 (
    echo ❌ Docker не найден!
    pause
    goto MENU
)

echo Выберите тип логов:
echo  1. Обычный режим
echo  2. Offline режим
echo  3. Статус контейнеров
set /p log_choice="Введите 1, 2 или 3: "

if "%log_choice%"=="1" (
    echo 📋 Логи обычного режима...
    docker-compose logs -f --tail=50 smb-processor
) else if "%log_choice%"=="2" (
    echo 📋 Логи offline режима...
    docker-compose -f docker-compose.offline.yml logs -f --tail=50 smb-processor
) else if "%log_choice%"=="3" (
    echo 📊 Статус контейнеров...
    docker ps -a
    echo.
    docker-compose ps
    pause
) else (
    echo Неверный выбор
    pause
)
goto MENU

:STOP_SERVICE
echo.
echo 🛑 Остановка сервиса...
echo =======================

REM Проверка Docker
where docker >nul 2>nul
if errorlevel 1 (
    echo ❌ Docker не найден!
    pause
    goto MENU
)

echo Какой сервис остановить?
echo  1. Обычный режим
echo  2. Offline режим
echo  3. Все контейнеры
set /p stop_choice="Введите 1, 2 или 3: "

if "%stop_choice%"=="1" (
    echo 🛑 Остановка обычного режима...
    docker-compose down
) else if "%stop_choice%"=="2" (
    echo 🛑 Остановка offline режима...
    docker-compose -f docker-compose.offline.yml down
) else if "%stop_choice%"=="3" (
    echo 🛑 Остановка всех контейнеров...
    docker stop $(docker ps -q) 2>nul
    docker-compose down 2>nul
    docker-compose -f docker-compose.offline.yml down 2>nul
) else (
    echo Неверный выбор
    pause
    goto MENU
)

echo ✅ Сервис остановлен
pause
goto MENU

:DIAGNOSTICS
echo.
echo 🔧 Диагностика системы...
echo =========================

echo 📋 Системная информация:
echo ========================
echo Дата/время: %date% %time%
echo Компьютер: %COMPUTERNAME%
echo Пользователь: %USERNAME%
echo.

echo 🐍 Проверка Python:
python --version 2>nul
if errorlevel 1 (
    echo ❌ Python не найден
) else (
    echo ✅ Python установлен
    where python
)
echo.

echo 🐳 Проверка Docker:
docker --version 2>nul
if errorlevel 1 (
    echo ❌ Docker не найден
) else (
    echo ✅ Docker установлен
    docker version --format "Server: {{.Server.Version}}, Client: {{.Client.Version}}" 2>nul
)
echo.

echo 📁 Проверка файлов проекта:
if exist app.py (echo ✅ app.py) else (echo ❌ app.py не найден)
if exist requirements.txt (echo ✅ requirements.txt) else (echo ❌ requirements.txt не найден)
if exist .env (echo ✅ .env) else (echo ⚠️ .env не настроен)
if exist .env.example (echo ✅ .env.example) else (echo ❌ .env.example не найден)
if exist test_smb3.py (echo ✅ test_smb3.py) else (echo ❌ test_smb3.py не найден)
echo.

echo 🌐 Проверка сети:
if defined SMB_HOST (
    echo Проверка SMB_HOST из .env...
    ping -n 1 %SMB_HOST% >nul 2>nul
    if errorlevel 1 (
        echo ❌ SMB сервер недоступен
    ) else (
        echo ✅ SMB сервер доступен
    )
) else (
    echo ⚠️ SMB_HOST не настроен в .env
)

echo 🔌 Проверка портов:
netstat -an | findstr ":3000 " >nul
if errorlevel 1 (
    echo ⚠️ Порт 3000 не используется
) else (
    echo ✅ Порт 3000 занят (возможно, сервис запущен)
)

echo.
echo 📊 Диагностика завершена
pause
goto MENU

:OPEN_VSCODE
echo.
echo 💻 Открытие в VS Code...
echo ========================

where code >nul 2>nul
if errorlevel 1 (
    echo ❌ VS Code не найден в PATH!
    echo    Установите VS Code или запустите из папки VS Code
    pause
    goto MENU
)

echo 🚀 Настройка VS Code для проекта...
if exist setup_vscode.ps1 (
    powershell -ExecutionPolicy Bypass -File setup_vscode.ps1
)

echo 📂 Открытие проекта в VS Code...
code .

echo ✅ VS Code запущен!
echo 💡 Полезные команды в VS Code:
echo    F5               - Запуск отладки
echo    Ctrl + Shift + P - Командная палитра  
echo    Ctrl + Shift + ` - Новый терминал
echo    Ctrl + R         - Запуск задачи
pause
goto MENU

:SHOW_DOCS
echo.
echo 📖 Документация...
echo ==================

echo 📋 Доступная документация:
echo.
if exist README_smb_processor.md (
    echo ✅ README_smb_processor.md - Основная документация
)
if exist WINDOWS_COMMANDS.md (
    echo ✅ WINDOWS_COMMANDS.md - Команды для Windows
)
if exist OFFLINE_INSTALL_GUIDE.md (
    echo ✅ OFFLINE_INSTALL_GUIDE.md - Автономная установка
)
if exist QUICK_START_SMB3.md (
    echo ✅ QUICK_START_SMB3.md - Быстрый старт
)

echo.
echo Какой файл открыть?
echo  1. Основная документация
echo  2. Windows команды
echo  3. Автономная установка
echo  4. Быстрый старт
echo  5. Все файлы в проводнике
set /p doc_choice="Введите 1-5: "

if "%doc_choice%"=="1" (
    if exist README_smb_processor.md (start README_smb_processor.md)
) else if "%doc_choice%"=="2" (
    if exist WINDOWS_COMMANDS.md (start WINDOWS_COMMANDS.md)
) else if "%doc_choice%"=="3" (
    if exist OFFLINE_INSTALL_GUIDE.md (start OFFLINE_INSTALL_GUIDE.md)
) else if "%doc_choice%"=="4" (
    if exist QUICK_START_SMB3.md (start QUICK_START_SMB3.md)
) else if "%doc_choice%"=="5" (
    explorer .
) else (
    echo Неверный выбор
)
pause
goto MENU

:EXIT
echo.
echo 👋 До свидания!
echo Спасибо за использование SMB3 File Processor
timeout /t 2 /nobreak >nul
exit /b

REM Обработка ошибок
:ERROR
echo ❌ Произошла ошибка!
pause
goto MENU
