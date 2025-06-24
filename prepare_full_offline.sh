#!/bin/bash

# Полная подготовка offline пакетов для SMB3 File Processor
# Включает загрузку Docker образов и Python пакетов

set -e

echo "🚀 Полная подготовка offline пакетов для SMB3 File Processor"
echo "============================================================"

# Проверка наличия Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не найден. Установите Docker для продолжения."
    exit 1
fi

# Проверка наличия Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 не найден. Установите Python3 для продолжения."
    exit 1
fi

# Проверка наличия pip
if ! command -v pip &> /dev/null; then
    echo "❌ pip не найден. Установите pip для продолжения."
    exit 1
fi

echo "📋 Шаг 1: Подготовка Python пакетов для offline установки"
echo "========================================================="

# Запуск скрипта подготовки Python пакетов
python3 prepare_offline.py

echo ""
echo "📋 Шаг 2: Сохранение Docker образов"
echo "===================================="

# Создание директории для Docker образов
mkdir -p docker_images

echo "📥 Загрузка базового образа Python..."
docker pull python:3.11-slim

echo "💾 Сохранение образа Python в файл..."
docker save python:3.11-slim -o docker_images/python-3.11-slim.tar

echo "🔨 Сборка offline образа SMB3 processor..."
docker build -f Dockerfile.offline -t smb3-processor-offline .

echo "💾 Сохранение образа SMB3 processor в файл..."
docker save smb3-processor-offline -o docker_images/smb3-processor-offline.tar

echo ""
echo "📋 Шаг 3: Создание скрипта автономной установки"
echo "==============================================="

cat > install_full_offline.sh << 'EOF'
#!/bin/bash

# Автономная установка SMB3 File Processor
echo "🚀 Автономная установка SMB3 File Processor"
echo "=========================================="

# Проверка наличия Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не найден. Установите Docker для продолжения."
    exit 1
fi

echo "📥 Загрузка Docker образов из файлов..."

# Загрузка базового образа Python
if [ -f "docker_images/python-3.11-slim.tar" ]; then
    echo "📦 Загрузка python:3.11-slim..."
    docker load -i docker_images/python-3.11-slim.tar
else
    echo "❌ Файл python-3.11-slim.tar не найден!"
    exit 1
fi

# Загрузка образа SMB3 processor
if [ -f "docker_images/smb3-processor-offline.tar" ]; then
    echo "📦 Загрузка smb3-processor-offline..."
    docker load -i docker_images/smb3-processor-offline.tar
else
    echo "❌ Файл smb3-processor-offline.tar не найден!"
    exit 1
fi

echo "✅ Docker образы загружены"

# Проверка наличия .env файла
if [ ! -f ".env" ]; then
    echo "📋 Создание файла конфигурации из шаблона..."
    cp .env.example .env
    echo "⚠️  ВНИМАНИЕ: Настройте параметры SMB3 в файле .env перед запуском!"
    echo "   Отредактируйте .env файл с правильными настройками SMB3."
    read -p "   Нажмите Enter когда настройки будут готовы..."
fi

echo "🚀 Запуск SMB3 File Processor..."
docker-compose -f docker-compose.offline.yml up -d

echo "⏳ Ожидание запуска сервиса..."
sleep 10

# Проверка состояния
if docker-compose -f docker-compose.offline.yml ps | grep -q "Up"; then
    echo "✅ SMB3 File Processor успешно запущен!"
    echo ""
    echo "📊 Статус контейнера:"
    docker-compose -f docker-compose.offline.yml ps
    echo ""
    echo "🌐 Проверка работоспособности:"
    
    # Попытка проверить health endpoint
    if curl -s http://localhost:3000/health > /dev/null; then
        echo "✅ Health check: OK"
        echo "🔗 Сервис доступен: http://localhost:3000"
        echo "🔗 Обработка файлов: http://localhost:3000/process"
    else
        echo "⚠️  Health check: Недоступен (возможно сервис еще запускается)"
    fi
    
    echo ""
    echo "📋 Полезные команды:"
    echo "   Логи:           docker-compose -f docker-compose.offline.yml logs -f"
    echo "   Остановка:      docker-compose -f docker-compose.offline.yml down"
    echo "   Перезапуск:     docker-compose -f docker-compose.offline.yml restart"
else
    echo "❌ Ошибка запуска сервиса!"
    echo "📋 Логи ошибок:"
    docker-compose -f docker-compose.offline.yml logs
    exit 1
fi

echo ""
echo "🎉 Автономная установка завершена успешно!"
EOF

# Делаем скрипт исполняемым
chmod +x install_full_offline.sh

echo ""
echo "📋 Шаг 4: Создание архива для передачи"
echo "======================================"

# Создание списка файлов для архива
cat > files_to_pack.txt << EOF
app.py
requirements.txt
.env.example
Dockerfile.offline
docker-compose.offline.yml
install_full_offline.sh
install_offline.sh
offline_packages/
docker_images/
README_smb_processor.md
OFFLINE_INSTALL_GUIDE.md
test_local.py
test_smb3.py
EOF

echo "📦 Создание архива smb3-processor-full-offline.tar.gz..."
tar --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' -czf smb3-processor-full-offline.tar.gz -T files_to_pack.txt

# Подсчет размеров
PYTHON_PACKAGES_SIZE=$(du -sh offline_packages/ | cut -f1)
DOCKER_IMAGES_SIZE=$(du -sh docker_images/ | cut -f1)
TOTAL_SIZE=$(du -sh smb3-processor-full-offline.tar.gz | cut -f1)

echo ""
echo "✅ Подготовка завершена успешно!"
echo ""
echo "📊 Статистика:"
echo "   Python пакеты:    $PYTHON_PACKAGES_SIZE"
echo "   Docker образы:    $DOCKER_IMAGES_SIZE"
echo "   Итоговый архив:   $TOTAL_SIZE"
echo ""
echo "📦 Создан архив: smb3-processor-full-offline.tar.gz"
echo ""
echo "📋 Инструкции для целевой машины без интернета:"
echo "1. Скопируйте архив smb3-processor-full-offline.tar.gz на целевую машину"
echo "2. Распакуйте: tar -xzf smb3-processor-full-offline.tar.gz"
echo "3. Перейдите в директорию и запустите: bash install_full_offline.sh"
echo ""
echo "⚠️  ВАЖНО: На целевой машине должен быть установлен только Docker!"

# Очистка временных файлов
rm -f files_to_pack.txt

echo ""
echo "🎉 Полная подготовка offline пакетов завершена!"
