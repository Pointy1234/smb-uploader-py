#!/bin/bash

# SMB File Processor - Скрипт остановки
echo "🛑 Остановка SMB File Processor..."

# Остановка и удаление контейнеров
docker-compose down

echo "✅ Сервис остановлен"

# Опциональная очистка
read -p "🗑️  Удалить Docker образы? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker-compose down --rmi all
    echo "✅ Образы удалены"
fi
