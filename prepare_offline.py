#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Скрипт подготовки offline пакетов для развертывания без интернета
Запускается на машине с интернетом для подготовки всех зависимостей
"""

import os
import subprocess
import sys
import shutil
from pathlib import Path

def run_command(cmd, description):
    """Выполнение команды с логированием"""
    print(f"📦 {description}...")
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        print(f"✅ {description} - успешно")
        if result.stdout:
            print(f"   Вывод: {result.stdout.strip()}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} - ошибка")
        print(f"   Ошибка: {e.stderr.strip()}")
        return False

def prepare_offline_packages():
    """Подготовка offline пакетов Python"""
    
    print("🚀 Подготовка offline пакетов для SMB File Processor")
    print("=" * 60)
    
    # Создание директории для offline пакетов
    offline_dir = Path("offline_packages")
    offline_dir.mkdir(exist_ok=True)
    
    # Очистка предыдущих пакетов
    if offline_dir.exists():
        shutil.rmtree(offline_dir)
    offline_dir.mkdir()
    
    print(f"📁 Создана директория: {offline_dir.absolute()}")
    
    # Скачивание Python пакетов
    print("\n📦 Скачивание Python зависимостей...")
    
    packages = [
        "Flask==3.0.0",
        "Werkzeug==3.0.1", 
        "smbprotocol==1.12.0",
        "pyspnego==0.10.2",
        "cryptography>=3.4.8",
        "ntlm-auth>=1.5.0",
        "requests==2.31.0",
        "python-dotenv==1.0.0",
        "six>=1.16.0",
        "urllib3==2.1.0",
        "pywin32; sys_platform == 'win32'",
        "setuptools",
        "wheel"
    ]
    
    for package in packages:
        if ";" in package and "win32" in package:
            continue  # Пропускаем Windows-specific пакеты для Linux
        
        cmd = f"pip download --dest {offline_dir} --no-deps {package}"
        if not run_command(cmd, f"Скачивание {package}"):
            print(f"⚠️  Не удалось скачать {package}, пробуем без версии...")
            base_package = package.split("==")[0]
            cmd = f"pip download --dest {offline_dir} --no-deps {base_package}"
            run_command(cmd, f"Скачивание {base_package}")
    
    # Скачивание зависимостей
    print("\n📦 Скачивание всех зависимостей...")
    cmd = f"pip download --dest {offline_dir} -r requirements.txt"
    run_command(cmd, "Скачивание всех зависимостей")
    
    # Создание requirements-offline.txt
    offline_requirements = offline_dir / "requirements-offline.txt"
    with open(offline_requirements, 'w') as f:
        f.write("# Offline requirements для SMB File Processor\n")
        f.write("# Установка: pip install --no-index --find-links ./offline_packages -r requirements-offline.txt\n\n")
        for package in packages:
            if ";" not in package:  # Исключаем условные пакеты
                f.write(f"{package}\n")
    
    print(f"📄 Создан файл: {offline_requirements}")
    
    # Подсчет скачанных файлов
    downloaded_files = list(offline_dir.glob("*.whl")) + list(offline_dir.glob("*.tar.gz"))
    print(f"\n📊 Скачано файлов: {len(downloaded_files)}")
    
    total_size = sum(f.stat().st_size for f in downloaded_files if f.is_file())
    print(f"📊 Общий размер: {total_size / 1024 / 1024:.1f} MB")
    
    # Список скачанных пакетов
    print("\n📦 Скачанные пакеты:")
    for file in sorted(downloaded_files):
        size_mb = file.stat().st_size / 1024 / 1024
        print(f"   {file.name} ({size_mb:.1f} MB)")
    
    return True

def create_offline_dockerfile():
    """Создание Dockerfile для offline установки"""
    
    dockerfile_content = '''# Offline Dockerfile для SMB File Processor
# Использует локальные пакеты без доступа к интернету

FROM python:3.11-slim

# Установка системных зависимостей для SMB (из локального кэша apt)
RUN apt-get update && apt-get install -y \\
    gcc \\
    libffi-dev \\
    libssl-dev \\
    smbclient \\
    cifs-utils \\
    && rm -rf /var/lib/apt/lists/*

# Создание рабочей директории
WORKDIR /app

# Копирование offline пакетов
COPY offline_packages/ ./offline_packages/

# Установка Python зависимостей из локальных пакетов
RUN pip install --no-cache-dir --upgrade pip && \\
    pip install --no-index --find-links ./offline_packages -r ./offline_packages/requirements-offline.txt

# Копирование исходного кода
COPY app.py .
COPY .env.example .env

# Создание пользователя без прав root для безопасности
RUN adduser --disabled-password --gecos '' appuser && \\
    chown -R appuser:appuser /app
USER appuser

# Открытие порта
EXPOSE 3000

# Команда запуска
CMD ["python", "app.py"]
'''
    
    with open("Dockerfile.offline", "w") as f:
        f.write(dockerfile_content)
    
    print("📄 Создан Dockerfile.offline для offline установки")

def create_offline_docker_compose():
    """Создание docker-compose для offline сборки"""
    
    compose_content = '''version: '3.8'

services:
  smb-processor:
    build:
      context: .
      dockerfile: Dockerfile.offline
    container_name: smb-file-processor-offline
    ports:
      - "3000:3000"
    environment:
      - SMB_HOST=${SMB_HOST}
      - SMB_SHARE=${SMB_SHARE}
      - SMB_USERNAME=${SMB_USERNAME}
      - SMB_PASSWORD=${SMB_PASSWORD}
      - SMB_DOMAIN=${SMB_DOMAIN:-WORKGROUP}
      - API_URL=${API_URL}
      - PORT=3000
      - SMB_INPUT_DIR=${SMB_INPUT_DIR:-input}
      - SMB_OUTPUT_DIR=${SMB_OUTPUT_DIR:-output}
    restart: unless-stopped
    networks:
      - smb-network

networks:
  smb-network:
    driver: bridge
'''
    
    with open("docker-compose.offline.yml", "w") as f:
        f.write(compose_content)
    
    print("📄 Создан docker-compose.offline.yml")

def create_install_script():
    """Создание скрипта установки offline пакетов"""
    
    install_script = '''#!/bin/bash

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
'''
    
    with open("install_offline.sh", "w") as f:
        f.write(install_script)
    
    # Делаем скрипт исполняемым
    try:
        os.chmod("install_offline.sh", 0o755)
    except:
        pass  # Игнорируем ошибки chmod на Windows
    print("📄 Создан install_offline.sh")

def main():
    """Основная функция"""
    
    # Проверка наличия requirements.txt
    if not Path("requirements.txt").exists():
        print("❌ Файл requirements.txt не найден!")
        sys.exit(1)
    
    # Проверка доступа к интернету
    if not run_command("pip --version", "Проверка pip"):
        print("❌ pip недоступен!")
        sys.exit(1)
    
    # Подготовка пакетов
    if not prepare_offline_packages():
        print("❌ Ошибка при подготовке offline пакетов")
        sys.exit(1)
    
    # Создание offline файлов
    create_offline_dockerfile()
    create_offline_docker_compose()
    create_install_script()
    
    print("\n🎉 Подготовка offline пакетов завершена!")
    print("\n📋 Следующие шаги:")
    print("1. Скопируйте всю директорию проекта на целевую машину")
    print("2. На целевой машине запустите: docker-compose -f docker-compose.offline.yml up --build -d")
    print("3. Или для локальной установки: bash install_offline.sh")
    
    print("\n📁 Созданные файлы для offline установки:")
    print("   - offline_packages/          (Python пакеты)")
    print("   - Dockerfile.offline         (Offline Dockerfile)")
    print("   - docker-compose.offline.yml (Offline Docker Compose)")
    print("   - install_offline.sh         (Скрипт локальной установки)")

if __name__ == "__main__":
    main()