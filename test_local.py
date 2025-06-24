#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Локальный тест SMB File Processor
"""

import os
import requests
import time
from dotenv import load_dotenv

# Загрузка переменных окружения
load_dotenv()

def test_health_endpoint():
    """Тест health endpoint"""
    try:
        response = requests.get('http://localhost:3000/health', timeout=5)
        if response.status_code == 200:
            print("✅ Health endpoint: OK")
            print(f"   Ответ: {response.json()}")
            return True
        else:
            print(f"❌ Health endpoint: HTTP {response.status_code}")
            return False
    except requests.RequestException as e:
        print(f"❌ Health endpoint: Ошибка подключения - {e}")
        return False

def test_process_endpoint():
    """Тест process endpoint"""
    try:
        print("📤 Отправка запроса на обработку файлов...")
        response = requests.get('http://localhost:3000/process', timeout=30)
        
        if response.status_code == 200:
            print("✅ Process endpoint: OK")
            print(f"   Ответ: {response.json()}")
            return True
        else:
            print(f"❌ Process endpoint: HTTP {response.status_code}")
            print(f"   Ошибка: {response.text}")
            return False
    except requests.RequestException as e:
        print(f"❌ Process endpoint: Ошибка подключения - {e}")
        return False

def main():
    print("🧪 Локальное тестирование SMB File Processor")
    print("=" * 50)
    
    # Проверка переменных окружения
    required_vars = ['SMB_HOST', 'SMB_SHARE', 'API_URL']
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        print(f"❌ Отсутствуют переменные окружения: {', '.join(missing_vars)}")
        print("   Настройте .env файл перед тестированием")
        return False
    
    print(f"📋 Конфигурация:")
    print(f"   SMB_HOST: {os.getenv('SMB_HOST')}")
    print(f"   SMB_SHARE: {os.getenv('SMB_SHARE')}")
    print(f"   API_URL: {os.getenv('API_URL')}")
    print()
    
    # Ожидание запуска сервиса
    print("⏳ Ожидание запуска сервиса...")
    max_attempts = 10
    
    for attempt in range(max_attempts):
        if test_health_endpoint():
            break
        time.sleep(2)
        print(f"   Попытка {attempt + 1}/{max_attempts}...")
    else:
        print("❌ Сервис недоступен после ожидания")
        return False
    
    print()
    
    # Тест обработки файлов
    success = test_process_endpoint()
    
    print()
    if success:
        print("🎉 Все тесты пройдены успешно!")
    else:
        print("❌ Некоторые тесты провалились")
    
    return success

if __name__ == '__main__':
    main()
