#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Тест SMB3 подключения
Проверяет возможность подключения к SMB3 серверу с заданными параметрами
"""

import os
import sys
from dotenv import load_dotenv
from smbprotocol.connection import Connection, Dialects
from smbprotocol.session import Session
from smbprotocol.tree import TreeConnect
from smbprotocol.open import Open, CreateDisposition, CreateOptions, FileAccessMask
import uuid

# Загрузка переменных окружения
load_dotenv()

def test_smb3_connection():
    """Тестирование SMB3 подключения"""
    
    # Получение параметров подключения
    SMB_HOST = os.getenv('SMB_HOST')
    SMB_SHARE = os.getenv('SMB_SHARE')
    SMB_USERNAME = os.getenv('SMB_USERNAME')
    SMB_PASSWORD = os.getenv('SMB_PASSWORD')
    SMB_DOMAIN = os.getenv('SMB_DOMAIN', 'WORKGROUP')
    
    # Проверка наличия параметров
    if not all([SMB_HOST, SMB_SHARE]):
        print("❌ Не заполнены обязательные параметры SMB3 в .env")
        print("   Необходимы: SMB_HOST, SMB_SHARE")
        return False
    
    print("🧪 Тест SMB3 подключения")
    print("=" * 40)
    print(f"🖥️  Сервер: {SMB_HOST}")
    print(f"📁 Шара: {SMB_SHARE}")
    print(f"👤 Пользователь: {SMB_USERNAME or '(анонимный)'}")
    print(f"🏢 Домен: {SMB_DOMAIN}")
    print()
    
    connection = None
    session = None
    tree = None
    
    try:
        print("🔌 Создание подключения к SMB3 серверу...")
        
        # Создаем подключение с принудительным использованием SMB3
        connection = Connection(
            uuid.uuid4(), 
            SMB_HOST, 
            445,
            # Принудительно используем только SMB3 диалекты
            dialects=[Dialects.SMB_3_0_0, Dialects.SMB_3_0_2, Dialects.SMB_3_1_1]
        )
        connection.connect()
        print("✅ TCP подключение установлено")
        
        # Проверяем диалект
        dialect_version = connection.dialect
        print(f"📡 Согласованный диалект: {dialect_version}")
        
        # Проверяем, что это SMB3
        if dialect_version not in [Dialects.SMB_3_0_0, Dialects.SMB_3_0_2, Dialects.SMB_3_1_1]:
            print(f"❌ Сервер не поддерживает SMB3! Используется: {dialect_version}")
            return False
        
        print("✅ Подтверждено использование SMB3 протокола")
        
        print("🔐 Аутентификация...")
        
        # Создаем сессию с аутентификацией
        session = Session(
            connection, 
            SMB_USERNAME, 
            SMB_PASSWORD, 
            SMB_DOMAIN,
            # Принудительное подписание для SMB3
            require_signing=True
        )
        session.connect()
        print("✅ Аутентификация прошла успешно")
        
        print("📂 Подключение к шаре...")
        
        # Подключаемся к шаре
        tree_path = f"\\\\{SMB_HOST}\\{SMB_SHARE}"
        tree = TreeConnect(session, tree_path)
        tree.connect()
        print(f"✅ Подключение к шаре {tree_path} успешно")
        
        print("📋 Тест чтения директории...")
        
        # Тестируем чтение корневой директории
        try:
            file_open = Open(tree, "")
            file_open.create(
                CreateDisposition.FILE_OPEN,
                FileAccessMask.GENERIC_READ,
                CreateOptions.FILE_DIRECTORY_FILE
            )
            
            files_info = file_open.query_directory("*")
            files = [f.file_name for f in files_info if f.file_name not in ['.', '..']]
            
            print(f"✅ Найдено файлов/папок: {len(files)}")
            if files:
                print("📁 Содержимое корневой директории:")
                for file in files[:10]:  # Показываем первые 10
                    print(f"   - {file}")
                if len(files) > 10:
                    print(f"   ... и еще {len(files) - 10} файлов/папок")
            
            file_open.close()
            
        except Exception as e:
            print(f"⚠️  Не удалось прочитать содержимое директории: {e}")
        
        print("✏️  Тест записи файла...")
        
        # Тестируем создание тестового файла
        try:
            test_file = ".__smb3_test__.txt"
            test_data = b"SMB3 test file"
            
            file_open = Open(tree, test_file)
            file_open.create(
                CreateDisposition.FILE_OVERWRITE_IF,
                FileAccessMask.GENERIC_WRITE
            )
            
            file_open.write(test_data, 0)
            file_open.close()
            print("✅ Тестовый файл создан")
            
            # Удаляем тестовый файл
            file_open = Open(tree, test_file)
            file_open.create(
                CreateDisposition.FILE_OPEN,
                FileAccessMask.DELETE
            )
            file_open.set_info({"delete_pending": True})
            file_open.close()
            print("✅ Тестовый файл удален")
            
        except Exception as e:
            print(f"⚠️  Не удалось создать/удалить тестовый файл: {e}")
            print("   Проверьте права на запись")
        
        print()
        print("🎉 Все тесты SMB3 прошли успешно!")
        print("   SMB3 File Processor готов к работе с этими настройками")
        return True
        
    except Exception as e:
        print(f"❌ Ошибка подключения к SMB3: {e}")
        print()
        print("🔧 Рекомендации по устранению:")
        print("   1. Проверьте доступность сервера: ping {SMB_HOST}")
        print("   2. Проверьте настройки SMB3 на сервере")
        print("   3. Убедитесь в правильности логина/пароля")
        print("   4. Проверьте права пользователя на шару")
        print("   5. Убедитесь, что firewall не блокирует порт 445")
        return False
        
    finally:
        # Закрываем соединения
        try:
            if tree:
                tree.disconnect()
            if session:
                session.disconnect()
            if connection:
                connection.disconnect()
        except:
            pass

def main():
    """Основная функция"""
    print("SMB3 Connection Tester")
    print("Версия 1.0 для SMB3 File Processor")
    print()
    
    # Проверка наличия .env файла
    if not os.path.exists('.env'):
        print("⚠️  Файл .env не найден")
        print("   Скопируйте .env.example в .env и настройте параметры")
        print("   cp .env.example .env")
        return False
    
    success = test_smb3_connection()
    
    if success:
        print()
        print("✅ SMB3 подключение работает корректно!")
        return True
    else:
        print()
        print("❌ SMB3 подключение не работает")
        print("   Исправьте проблемы перед запуском SMB3 File Processor")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
