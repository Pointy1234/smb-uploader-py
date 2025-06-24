#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SMB файловый процессор - Python версия
Обрабатывает изображения из SMB шары и отправляет их на API endpoint
"""

import os
import base64
import logging
import tempfile
from pathlib import Path
from typing import List, Optional
import threading
import time

from flask import Flask, jsonify, request
from smbprotocol.connection import Connection, Dialects
from smbprotocol.session import Session
from smbprotocol.tree import TreeConnect
from smbprotocol.open import Open, CreateDisposition, CreateOptions, FileAccessMask, ShareAccess
from smbprotocol.file_info import FileInformationClass
from smbprotocol.exceptions import SMBResponseException
import requests
from dotenv import load_dotenv
import uuid

# Загрузка переменных окружения
load_dotenv()

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
    ]
)
logger = logging.getLogger(__name__)

# Конфигурация из переменных окружения
SMB_HOST = os.getenv('SMB_HOST')
SMB_SHARE = os.getenv('SMB_SHARE')
SMB_USERNAME = os.getenv('SMB_USERNAME')
SMB_PASSWORD = os.getenv('SMB_PASSWORD')
SMB_DOMAIN = os.getenv('SMB_DOMAIN', 'WORKGROUP')
API_URL = os.getenv('API_URL')
PORT = int(os.getenv('PORT', 3000))
SMB_INPUT_DIR = os.getenv('SMB_INPUT_DIR', 'input')
SMB_OUTPUT_DIR = os.getenv('SMB_OUTPUT_DIR', 'output')

# Проверка обязательных параметров
if not all([SMB_HOST, SMB_SHARE, API_URL]):
    logger.error('Не заполнены все обязательные переменные в .env')
    exit(1)

logger.info(' Конфигурация подключения:')
logger.info(f' SMB_HOST: {SMB_HOST}')
logger.info(f' SMB_SHARE: {SMB_SHARE}')
logger.info(f' SMB_USERNAME: {SMB_USERNAME or "(не задан)"}')
logger.info(f' API_URL: {API_URL}')
logger.info(f' PORT: {PORT}')
logger.info(f' INPUT DIR: {SMB_INPUT_DIR}')
logger.info(f' OUTPUT DIR: {SMB_OUTPUT_DIR}')

app = Flask(__name__)

class SMBClient:
    """SMB3 клиент для работы с файлами"""
    
    def __init__(self):
        self.server_name = SMB_HOST
        self.share_name = SMB_SHARE
        self.username = SMB_USERNAME
        self.password = SMB_PASSWORD
        self.domain = SMB_DOMAIN
        self.connection = None
        self.session = None
        self.tree = None
        self.connected = False
        
    def connect(self):
        """Подключение к SMB3 серверу"""
        try:
            # Создаем подключение с принудительным использованием SMB3
            self.connection = Connection(
                uuid.uuid4(), 
                self.server_name, 
                445,
                # Принудительно используем только SMB3 диалекты
                dialects=[Dialects.SMB_3_0_0, Dialects.SMB_3_0_2, Dialects.SMB_3_1_1]
            )
            self.connection.connect()
            
            # Создаем сессию с аутентификацией
            self.session = Session(
                self.connection, 
                self.username, 
                self.password, 
                self.domain,
                # Принудительное подписание для SMB3
                require_signing=True
            )
            self.session.connect()
            
            # Подключаемся к шаре
            tree_path = f"\\\\{self.server_name}\\{self.share_name}"
            self.tree = TreeConnect(self.session, tree_path)
            self.tree.connect()
            
            # Проверяем, что используется SMB3
            dialect_version = self.connection.dialect
            logger.info(f'✅ Успешное подключение к SMB3: {tree_path}')
            logger.info(f'📡 Используемый диалект: {dialect_version}')
            
            # Проверяем, что это действительно SMB3
            if dialect_version in [Dialects.SMB_3_0_0, Dialects.SMB_3_0_2, Dialects.SMB_3_1_1]:
                logger.info('✅ Подтверждено использование SMB3 протокола')
                self.connected = True
                return True
            else:
                logger.error(f'❌ Используется неподдерживаемый диалект: {dialect_version}')
                self.disconnect()
                return False
            
        except Exception as e:
            logger.error(f'❌ Ошибка подключения к SMB3: {e}')
            self.connected = False
            return False
    
    def disconnect(self):
        """Отключение от SMB сервера"""
        try:
            if self.tree:
                self.tree.disconnect()
            if self.session:
                self.session.disconnect()
            if self.connection:
                self.connection.disconnect()
            self.connected = False
            logger.info('✅ Отключение от SMB3 сервера')
        except Exception as e:
            logger.error(f'Ошибка при отключении от SMB3: {e}')
    
    def list_files(self, directory: str = '') -> List[str]:
        """Получение списка файлов в директории"""
        try:
            if not self.connected:
                raise Exception("Нет подключения к SMB3")
            
            # Формируем путь для поиска
            search_path = directory.replace('/', '\\').strip('\\') if directory else ""
            
            # Открываем директорию для чтения
            file_open = Open(self.tree, search_path)
            file_open.create(
                CreateDisposition.FILE_OPEN,
                FileAccessMask.GENERIC_READ,
                CreateOptions.FILE_DIRECTORY_FILE,
                share_access=ShareAccess.FILE_SHARE_READ | ShareAccess.FILE_SHARE_WRITE
            )
            
            # Получаем список файлов
            files_info = file_open.query_directory("*", FileInformationClass.FILE_DIRECTORY_INFORMATION)
            
            files = []
            for file_info in files_info:
                if file_info.file_name not in ['.', '..']:
                    files.append(file_info.file_name)
            
            file_open.close()
            return files
            
        except Exception as e:
            logger.error(f'Ошибка получения списка файлов из {directory}: {e}')
            return []
    
    def read_file(self, file_path: str) -> Optional[bytes]:
        """Чтение файла"""
        try:
            if not self.connected:
                raise Exception("Нет подключения к SMB3")
            
            # Формируем правильный путь
            clean_path = file_path.replace('/', '\\').strip('\\')
            
            file_open = Open(self.tree, clean_path)
            file_open.create(
                CreateDisposition.FILE_OPEN,
                FileAccessMask.GENERIC_READ,
                share_access=ShareAccess.FILE_SHARE_READ
            )
            
            # Получаем размер файла
            file_info = file_open.query_info(FileInformationClass.FILE_STANDARD_INFORMATION)
            file_size = file_info.end_of_file
            
            # Читаем файл
            data = file_open.read(0, file_size)
            file_open.close()
            
            return data
            
        except Exception as e:
            logger.error(f'Ошибка чтения файла {file_path}: {e}')
            return None
    
    def write_file(self, file_path: str, data: bytes) -> bool:
        """Запись файла"""
        try:
            if not self.connected:
                raise Exception("Нет подключения к SMB3")
            
            # Формируем правильный путь
            clean_path = file_path.replace('/', '\\').strip('\\')
            
            file_open = Open(self.tree, clean_path)
            file_open.create(
                CreateDisposition.FILE_OVERWRITE_IF,  # Создаем или перезаписываем
                FileAccessMask.GENERIC_WRITE,
                share_access=ShareAccess.FILE_SHARE_READ
            )
            
            file_open.write(data, 0)
            file_open.close()
            
            return True
            
        except Exception as e:
            logger.error(f'Ошибка записи файла {file_path}: {e}')
            return False
    
    def delete_file(self, file_path: str) -> bool:
        """Удаление файла"""
        try:
            if not self.connected:
                raise Exception("Нет подключения к SMB3")
            
            # Формируем правильный путь
            clean_path = file_path.replace('/', '\\').strip('\\')
            
            file_open = Open(self.tree, clean_path)
            file_open.create(
                CreateDisposition.FILE_OPEN,
                FileAccessMask.DELETE,
                share_access=ShareAccess.FILE_SHARE_DELETE
            )
            
            # Помечаем файл для удаления
            file_open.set_info({"delete_pending": True})
            file_open.close()
            
            return True
            
        except Exception as e:
            logger.error(f'Ошибка удаления файла {file_path}: {e}')
            return False

# Глобальный SMB клиент
smb_client = SMBClient()

def initialize_smb():
    """Инициализация SMB подключения"""
    try:
        success = smb_client.connect()
        if success:
            # Проверяем доступность корневой директории
            root_files = smb_client.list_files('')
            logger.info(f' Доступные папки/файлы в корне SMB: {root_files}')
        return success
    except Exception as e:
        logger.error(f' Ошибка подключения к SMB-шаре при инициализации: {e}')
        logger.error(f' Подключение к \\\\{SMB_HOST}\\{SMB_SHARE}')
        return False

def is_image_file(filename: str) -> bool:
    """Проверка, является ли файл изображением"""
    image_extensions = {'.png', '.jpg', '.jpeg', '.gif', '.bmp', '.tiff', '.webp'}
    return Path(filename).suffix.lower() in image_extensions

def process_files():
    """Основная функция обработки файлов"""
    logger.info('[PROCESS] Запуск обработки файлов из SMB')
    
    input_path = SMB_INPUT_DIR
    output_path = SMB_OUTPUT_DIR
    
    try:
        # Тест записи
        test_file = f"{input_path}\\.__smb_test__.txt"
        test_data = b'test'
        
        logger.info(f'[PROCESS] Проверка записи: создание тестового файла {test_file}')
        if smb_client.write_file(test_file, test_data):
            logger.info('[PROCESS] Тестовый файл создан')
            
            logger.info(f'[PROCESS] Удаление тестового файла {test_file}')
            if smb_client.delete_file(test_file):
                logger.info('[PROCESS] Тестовый файл удалён')
        
        # Получение списка файлов
        logger.info(f'[PROCESS] Чтение списка файлов из {input_path}')
        files = smb_client.list_files(input_path)
        logger.info(f'[PROCESS] Найдено файлов: {len(files)}')
        
        # Фильтрация изображений
        image_files = [f for f in files if is_image_file(f)]
        
        if not image_files:
            logger.info(' Нет изображений для обработки')
            return {'message': 'Нет изображений для обработки'}
        
        # Обработка каждого изображения
        for file in image_files:
            full_path = f"{input_path}\\{file}"
            output_full_path = f"{output_path}\\{file}"
            
            logger.info(f'[PROCESS] Чтение файла: {full_path}')
            buffer = smb_client.read_file(full_path)
            
            if not buffer:
                logger.error(f'[PROCESS] Ошибка чтения файла {file}')
                continue
            
            logger.info(f'[PROCESS] Файл {file} прочитан, размер {len(buffer)} байт')
            
            # Кодирование в base64
            base64_data = base64.b64encode(buffer).decode('utf-8')
            
            # Отправка на API
            logger.info(f'[PROCESS] Отправка изображения {file} на API в JSON...')
            try:
                response = requests.post(
                    API_URL,
                    json={
                        'filename': file,
                        'filedata': base64_data
                    },
                    headers={'Content-Type': 'application/json'},
                    timeout=10
                )
                response.raise_for_status()
                logger.info(f'[PROCESS] Файл {file} успешно отправлен на API')
            except requests.RequestException as e:
                logger.error(f'[PROCESS] Ошибка при отправке файла {file}: {e}')
                continue
            
            # Перемещение файла
            logger.info(f'[PROCESS] Перенос файла в папку output: {file}')
            try:
                if smb_client.write_file(output_full_path, buffer):
                    if smb_client.delete_file(full_path):
                        logger.info(f'[PROCESS] Файл {file} перемещён в output')
                    else:
                        logger.error(f'[PROCESS] Ошибка при удалении исходного файла {file}')
                else:
                    logger.error(f'[PROCESS] Ошибка при записи файла {file} в output')
            except Exception as e:
                logger.error(f'[PROCESS] Ошибка при переносе файла {file}: {e}')
        
        return {'message': 'Все изображения отправлены и перемещены в output'}
        
    except Exception as error:
        logger.error(f'[PROCESS] Ошибка выполнения процесса: {error}')
        raise error

@app.route('/process', methods=['GET'])
def process_endpoint():
    """Endpoint для обработки файлов"""
    try:
        result = process_files()
        return jsonify(result)
    except Exception as e:
        logger.error(f'[PROCESS] Ошибка выполнения процесса: {e}')
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Endpoint для проверки здоровья сервиса"""
    return jsonify({'status': 'healthy', 'timestamp': '2025-06-25 02:26:44'})

if __name__ == '__main__':
    # Инициализация SMB при запуске
    initialize_smb()
    
    logger.info(f' Сервер запущен: http://localhost:{PORT}')
    app.run(host='0.0.0.0', port=PORT, debug=False)
