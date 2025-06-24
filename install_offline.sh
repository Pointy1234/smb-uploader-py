#!/bin/bash

# Установка offline пакетов SMB3 File Processor
echo "📦 Установка offline пакетов Python для SMB3 File Processor..."

# Проверка наличия offline_packages
if [ ! -d "offline_packages" ]; then
    echo "❌ Директория offline_packages не найдена!"
    echo "   Запустите prepare_offline.py на машине с интернетом"
    exit 1
fi

# Проверка наличия requirements файла
if [ ! -f "offline_packages/requirements-offline.txt" ]; then
    echo "❌ Файл requirements-offline.txt не найден в offline_packages!"
    echo "   Запустите prepare_offline.py на машине с интернетом"
    exit 1
fi

echo "📋 Найдено пакетов для установки:"
ls -1 offline_packages/*.whl offline_packages/*.tar.gz 2>/dev/null | wc -l

echo "🔧 Установка Python пакетов из offline_packages..."

# Установка пакетов
if pip install --no-index --find-links ./offline_packages -r ./offline_packages/requirements-offline.txt; then
    echo "✅ Offline пакеты для SMB3 успешно установлены"
    
    echo "🧪 Проверка установки..."
    python -c "
import flask
import smbprotocol
import requests
import dotenv
print('✅ Все основные модули импортированы успешно')
print(f'   Flask: {flask.__version__}')
print(f'   SMBProtocol: {smbprotocol.__version__}')
print(f'   Requests: {requests.__version__}')
"
    
    echo ""
    echo "🚀 Готово! Теперь можно запустить приложение:"
    echo "   python app.py"
    
else
    echo "❌ Ошибка при установке offline пакетов"
    echo "   Проверьте логи выше для диагностики"
    exit 1
fi
