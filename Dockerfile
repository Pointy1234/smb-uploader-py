# Используем официальный Python образ для SMB3
FROM python:3.11-slim

# Установка системных зависимостей для SMB3
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libffi-dev \
    libssl-dev \
    libkrb5-dev \
    build-essential \
    smbclient \
    cifs-utils \
    && rm -rf /var/lib/apt/lists/*

# Создание рабочей директории
WORKDIR /app

# Копирование файлов зависимостей
COPY requirements.txt .

# Установка Python зависимостей
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Копирование исходного кода
COPY app.py .
COPY .env.example .env

# Создание пользователя без прав root для безопасности
RUN adduser --disabled-password --gecos '' appuser && \
    chown -R appuser:appuser /app
USER appuser

# Открытие порта
EXPOSE 3000

# Команда запуска
CMD ["python", "app.py"]
