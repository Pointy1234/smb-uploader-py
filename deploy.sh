#!/bin/bash

# SMB File Processor - Скрипт развертывания
# Python версия портированного Node.js приложения

set -e

echo "🚀 SMB File Processor - Развертывание Python версии"
echo "=================================================="

# Проверка наличия Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не найден. Установите Docker для продолжения."
    exit 1
fi

# Проверка наличия Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose не найден. Установите Docker Compose для продолжения."
    exit 1
fi

# Проверка наличия .env файла
if [ ! -f ".env" ]; then
    echo "📋 Создание файла конфигурации из шаблона..."
    cp .env.example .env
    echo "⚠️  ВНИМАНИЕ: Настройте параметры в файле .env перед запуском!"
    echo "   Отредактируйте .env файл с правильными настройками SMB и API."
    read -p "   Нажмите Enter когда настройки будут готовы..."
fi

echo "🔨 Сборка Docker образа..."
docker-compose build

echo "🚀 Запуск контейнера..."
docker-compose up -d

echo "⏳ Ожидание запуска сервиса..."
sleep 5

# Проверка состояния
if docker-compose ps | grep -q "Up"; then
    echo "✅ Сервис успешно запущен!"
    echo ""
    echo "📊 Статус контейнера:"
    docker-compose ps
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
    echo "   Логи:           docker-compose logs -f"
    echo "   Остановка:      docker-compose down"
    echo "   Перезапуск:     docker-compose restart"
    echo "   Вход в контейнер: docker-compose exec smb-processor /bin/bash"
else
    echo "❌ Ошибка запуска сервиса!"
    echo "📋 Логи ошибок:"
    docker-compose logs
    exit 1
fi

echo ""
echo "🎉 Развертывание завершено успешно!"
