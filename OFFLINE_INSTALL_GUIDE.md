# Руководство по автономной установке SMB3 File Processor

Данное руководство описывает процесс установки SMB3 File Processor на машинах без доступа к интернету.

## 📋 Предварительные требования

### На машине с интернетом (для подготовки)
- Docker
- Python 3.7+
- pip
- bash
- 2GB свободного места

### На целевой машине (без интернета)
- **Только Docker** (версия 20.10+)
- 1GB свободного места
- Доступ к SMB3 серверу

## 🚀 Процесс развертывания

### Шаг 1: Подготовка на машине с интернетом

```bash
# 1. Клонируйте или скопируйте проект
git clone <repository> smb3-processor
cd smb3-processor

# 2. Запустите полную подготовку offline пакетов
bash prepare_full_offline.sh
```

**Что произойдет:**
- Скачаются все Python зависимости
- Загрузятся Docker образы
- Создастся архив `smb3-processor-full-offline.tar.gz`

**Время выполнения:** 5-15 минут в зависимости от скорости интернета

**Размер архива:** ~500MB - 1GB

### Шаг 2: Передача на целевую машину

```bash
# Скопируйте архив на целевую машину любым доступным способом
scp smb3-processor-full-offline.tar.gz user@target-machine:/tmp/
# или USB, сетевая папка, и т.д.
```

### Шаг 3: Установка на целевой машине

```bash
# 1. Распакуйте архив
cd /tmp
tar -xzf smb3-processor-full-offline.tar.gz
cd smb3-processor-full-offline/

# 2. Настройте конфигурацию
cp .env.example .env
nano .env  # или любой другой редактор
```

**Настройка .env файла:**
```env
# SMB3 Configuration
SMB_HOST=192.168.1.100          # IP адрес SMB3 сервера
SMB_SHARE=shared_folder         # Имя SMB3 шары
SMB_USERNAME=your_username      # Пользователь с доступом к SMB3
SMB_PASSWORD=your_password      # Пароль пользователя
SMB_DOMAIN=WORKGROUP           # Домен (или WORKGROUP)

# API Configuration
API_URL=http://api-server:8080/api/process  # URL вашего API

# Directories
SMB_INPUT_DIR=input            # Папка для входящих изображений
SMB_OUTPUT_DIR=output          # Папка для обработанных изображений
```

```bash
# 3. Запустите автономную установку
bash install_full_offline.sh
```

**Что произойдет:**
- Загрузятся Docker образы из архива
- Запустится SMB3 File Processor контейнер
- Проверится работоспособность сервиса

## 🔍 Проверка установки

### Проверка состояния сервиса

```bash
# Статус контейнера
docker-compose -f docker-compose.offline.yml ps

# Логи сервиса
docker-compose -f docker-compose.offline.yml logs -f

# Health check
curl http://localhost:3000/health
```

**Ожидаемый ответ health check:**
```json
{
  "status": "healthy",
  "timestamp": "2025-06-25 02:33:47"
}
```

### Проверка подключения к SMB3

В логах должны быть сообщения:
```
✅ Успешное подключение к SMB3: \\192.168.1.100\shared_folder
📡 Используемый диалект: SMB_3_0_2
✅ Подтверждено использование SMB3 протокола
```

### Тестовая обработка файлов

```bash
# Запуск обработки файлов
curl http://localhost:3000/process
```

## 🛠️ Управление сервисом

### Основные команды

```bash
# Остановка
docker-compose -f docker-compose.offline.yml down

# Запуск
docker-compose -f docker-compose.offline.yml up -d

# Перезапуск
docker-compose -f docker-compose.offline.yml restart

# Просмотр логов
docker-compose -f docker-compose.offline.yml logs -f smb-processor

# Статус
docker-compose -f docker-compose.offline.yml ps
```

### Изменение конфигурации

```bash
# 1. Остановите сервис
docker-compose -f docker-compose.offline.yml down

# 2. Отредактируйте .env
nano .env

# 3. Запустите снова
docker-compose -f docker-compose.offline.yml up -d
```

## 🔧 Устранение неполадок

### Сервис не запускается

```bash
# Проверьте логи
docker-compose -f docker-compose.offline.yml logs

# Проверьте образы
docker images | grep smb3-processor

# Перезагрузите образы
docker load -i docker_images/smb3-processor-offline.tar
```

### SMB3 подключение не работает

```bash
# Войдите в контейнер
docker exec -it smb-file-processor-offline /bin/bash

# Тестируйте SMB3 подключение
smbclient //SMB_HOST/SMB_SHARE -U SMB_USERNAME --max-protocol=SMB3
```

### Health check не отвечает

```bash
# Проверьте, что контейнер запущен
docker ps | grep smb3-processor

# Проверьте порты
netstat -tlnp | grep 3000

# Проверьте изнутри контейнера
docker exec -it smb-file-processor-offline curl http://localhost:3000/health
```

## 📊 Мониторинг

### Автоматический мониторинг

Создайте скрипт мониторинга:

```bash
cat > monitor.sh << 'EOF'
#!/bin/bash
while true; do
    if curl -s http://localhost:3000/health > /dev/null; then
        echo "$(date): SMB3 Processor - OK"
    else
        echo "$(date): SMB3 Processor - ERROR"
        # Опционально: перезапуск сервиса
        # docker-compose -f docker-compose.offline.yml restart
    fi
    sleep 60
done
EOF

chmod +x monitor.sh
nohup ./monitor.sh > monitor.log 2>&1 &
```

### Логирование

```bash
# Настройка ротации логов Docker
echo '{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}' > /etc/docker/daemon.json

systemctl restart docker
```

## 🔄 Обновление

Для обновления сервиса:

1. Подготовьте новую версию на машине с интернетом
2. Создайте новый архив
3. На целевой машине:

```bash
# Остановите текущий сервис
docker-compose -f docker-compose.offline.yml down

# Обновите файлы
tar -xzf smb3-processor-full-offline-new.tar.gz

# Загрузите новые образы
docker load -i docker_images/smb3-processor-offline.tar

# Запустите обновленный сервис
docker-compose -f docker-compose.offline.yml up -d
```

## 📋 Контрольный список

- [ ] Docker установлен и запущен на целевой машине
- [ ] Архив скопирован и распакован
- [ ] Файл .env настроен с правильными SMB3 параметрами
- [ ] SMB3 сервер доступен с целевой машины
- [ ] Права пользователя настроены на SMB3 шаре
- [ ] Папки input и output существуют на SMB3 шаре
- [ ] API endpoint доступен с целевой машины
- [ ] Файрвол не блокирует порт 3000
- [ ] Health check возвращает статус "healthy"
- [ ] Тестовая обработка файлов работает

## 🎯 Результат

После успешной установки у вас будет:

- SMB3 File Processor работающий в Docker контейнере
- Автоматическая обработка изображений из SMB3 шары
- Веб-интерфейс для мониторинга и управления
- Полностью автономная работа без интернета
- Безопасное соединение только по SMB3 протоколу

**Время установки:** 5-10 минут
**Требования к ресурсам:** 100-200MB RAM, 1GB диск
