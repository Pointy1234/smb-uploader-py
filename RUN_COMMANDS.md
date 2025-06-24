# 🚀 Команды запуска и тестирования SMB3 File Processor

## 📋 СЦЕНАРИЙ 1: Машина С интернетом

### 1. Настройка конфигурации
```bash
# Копируем шаблон конфигурации
cp .env.example .env

# Редактируем настройки SMB3 (обязательно!)
nano .env
```

**Пример .env файла:**
```env
SMB_HOST=192.168.1.100
SMB_SHARE=shared_folder
SMB_USERNAME=your_username
SMB_PASSWORD=your_password
SMB_DOMAIN=WORKGROUP
API_URL=http://your-api:8080/api/process
SMB_INPUT_DIR=input
SMB_OUTPUT_DIR=output
```

### 2. Тестирование SMB3 подключения
```bash
# Установка зависимостей (если запускаете локально)
pip install -r requirements.txt

# Тест подключения к SMB3 серверу
python test_smb3.py
```

**Ожидаемый результат:**
```
✅ Успешное подключение к SMB3: \\192.168.1.100\shared_folder
📡 Используемый диалект: SMB_3_0_2
✅ Подтверждено использование SMB3 протокола
✅ Найдено файлов/папок: 5
✅ Тестовый файл создан
✅ Тестовый файл удален
🎉 Все тесты SMB3 прошли успешно!
```

### 3. Запуск с Docker
```bash
# Сборка и запуск контейнера
docker-compose up --build -d

# Проверка статуса
docker-compose ps

# Просмотр логов
docker-compose logs -f smb-processor
```

### 4. Локальный запуск (без Docker)
```bash
# Установка зависимостей
pip install -r requirements.txt

# Запуск приложения
python app.py
```

## 📋 СЦЕНАРИЙ 2: Машина БЕЗ интернета (рекомендуется)

### Шаг A: Подготовка на машине с интернетом

```bash
# 1. Подготовка всех offline пакетов
bash prepare_full_offline.sh

# Результат: создастся архив smb3-processor-full-offline.tar.gz (~500MB-1GB)
ls -lh smb3-processor-full-offline.tar.gz
```

**Что включает архив:**
- Docker образы (Python + SMB3 processor)
- Python пакеты offline
- Исходный код
- Скрипты установки
- Документация

### Шаг B: Передача на целевую машину

```bash
# Копирование архива любым доступным способом
scp smb3-processor-full-offline.tar.gz user@target-machine:/tmp/
# или USB, сетевая папка, и т.д.
```

### Шаг C: Установка на целевой машине (без интернета)

```bash
# 1. Распаковка
cd /tmp
tar -xzf smb3-processor-full-offline.tar.gz
cd smb3-processor-full-offline/

# 2. Настройка конфигурации
cp .env.example .env
nano .env  # настроить SMB3 параметры

# 3. Тест SMB3 подключения
python test_smb3.py

# 4. Автономная установка и запуск
bash install_full_offline.sh
```

## 🧪 КОМАНДЫ ТЕСТИРОВАНИЯ

### 1. Health Check (проверка работоспособности)
```bash
# Базовая проверка
curl http://localhost:3000/health

# С подробным выводом
curl -v http://localhost:3000/health

# Ожидаемый ответ:
# {"status": "healthy", "timestamp": "2025-06-25 02:40:59"}
```

### 2. Тест обработки файлов
```bash
# Запуск обработки
curl http://localhost:3000/process

# С подробным выводом
curl -v http://localhost:3000/process

# Ожидаемые ответы:
# {"message": "Нет изображений для обработки"}  - если нет файлов
# {"message": "Все изображения отправлены и перемещены в output"}  - при успехе
```

### 3. Автоматический тест API
```bash
# Запуск встроенного тестера
python test_local.py
```

**Пример вывода test_local.py:**
```
🧪 Локальное тестирование SMB3 File Processor
==================================================
📋 Конфигурация:
   SMB_HOST: 192.168.1.100
   SMB_SHARE: shared_folder
   API_URL: http://api-server:8080/api/process

✅ Health endpoint: OK
   Ответ: {'status': 'healthy', 'timestamp': '2025-06-25 02:40:59'}

📤 Отправка запроса на обработку файлов...
✅ Process endpoint: OK
   Ответ: {'message': 'Нет изображений для обработки'}

🎉 Все тесты пройдены успешно!
```

### 4. Диагностика SMB3 подключения
```bash
# Полная диагностика SMB3
python test_smb3.py

# Тест из командной строки (если smbclient установлен)
smbclient -L //192.168.1.100 -U username --max-protocol=SMB3

# Тест конкретной шары
smbclient //192.168.1.100/shared_folder -U username --max-protocol=SMB3
```

## 📊 МОНИТОРИНГ И ЛОГИ

### 1. Просмотр логов
```bash
# Docker версия (с интернетом)
docker-compose logs -f smb-processor

# Docker версия (offline)
docker-compose -f docker-compose.offline.yml logs -f smb-processor

# Только последние 100 строк
docker-compose logs --tail=100 smb-processor

# Логи в реальном времени
docker-compose logs -f --tail=0 smb-processor
```

### 2. Статус контейнера
```bash
# Статус сервисов
docker-compose ps

# Или для offline версии
docker-compose -f docker-compose.offline.yml ps

# Детальная информация
docker inspect smb-file-processor-offline
```

### 3. Вход в контейнер для отладки
```bash
# Вход в контейнер
docker exec -it smb-file-processor-offline /bin/bash

# Внутри контейнера можно:
# - Проверить файлы: ls -la
# - Тестировать SMB: python test_smb3.py
# - Проверить процессы: ps aux
# - Проверить сеть: netstat -tlnp
```

### 4. Мониторинг ресурсов
```bash
# Использование ресурсов
docker stats smb-file-processor-offline

# Логи системы
journalctl -u docker -f
```

## 🛠️ УПРАВЛЕНИЕ СЕРВИСОМ

### 1. Остановка
```bash
# Остановка (с интернетом)
docker-compose down

# Остановка (offline)
docker-compose -f docker-compose.offline.yml down

# Или через скрипт
bash stop.sh
```

### 2. Перезапуск
```bash
# Перезапуск
docker-compose restart

# Или для offline
docker-compose -f docker-compose.offline.yml restart

# Полный пересборка
docker-compose down && docker-compose up --build -d
```

### 3. Обновление конфигурации
```bash
# 1. Остановить сервис
docker-compose down

# 2. Изменить .env
nano .env

# 3. Перезапустить
docker-compose up -d
```

## 🔧 УСТРАНЕНИЕ НЕПОЛАДОК

### 1. Сервис не запускается
```bash
# Проверить логи
docker-compose logs smb-processor

# Проверить образы
docker images | grep smb

# Пересоздать контейнер
docker-compose down
docker-compose up --build -d
```

### 2. SMB3 не подключается
```bash
# Запустить тест
python test_smb3.py

# Проверить сетевую доступность
ping 192.168.1.100
telnet 192.168.1.100 445

# Тест через smbclient
smbclient -L //192.168.1.100 -U username --max-protocol=SMB3
```

### 3. API не отвечает
```bash
# Проверить порты
netstat -tlnp | grep 3000

# Тест изнутри контейнера
docker exec -it smb-file-processor-offline curl http://localhost:3000/health

# Проверить firewall
sudo ufw status
```

## ✅ КОНТРОЛЬНЫЙ СПИСОК ПРОВЕРКИ

### Перед запуском:
- [ ] Файл .env настроен с правильными SMB3 параметрами
- [ ] SMB3 сервер доступен (ping + telnet 445)
- [ ] Пользователь имеет права на SMB3 шару
- [ ] Папки input/output существуют на шаре
- [ ] API endpoint доступен
- [ ] Docker установлен и запущен

### После запуска:
- [ ] Health check возвращает {"status": "healthy"}
- [ ] Логи показывают успешное SMB3 подключение
- [ ] Нет ошибок в docker-compose logs
- [ ] Process endpoint отвечает без ошибок
- [ ] Тестовые файлы обрабатываются корректно

## 🎯 БЫСТРЫЕ КОМАНДЫ

```bash
# Полный цикл тестирования (с интернетом)
cp .env.example .env && \
nano .env && \
python test_smb3.py && \
docker-compose up --build -d && \
sleep 10 && \
curl http://localhost:3000/health && \
curl http://localhost:3000/process

# Полный цикл тестирования (offline)
cp .env.example .env && \
nano .env && \
python test_smb3.py && \
bash install_full_offline.sh && \
sleep 10 && \
curl http://localhost:3000/health && \
curl http://localhost:3000/process
```

## 📞 Экстренное восстановление

```bash
# Полная очистка и пересоздание
docker-compose down
docker system prune -f
docker-compose up --build -d

# Для offline версии
docker-compose -f docker-compose.offline.yml down
docker load -i docker_images/smb3-processor-offline.tar
docker-compose -f docker-compose.offline.yml up -d
```
