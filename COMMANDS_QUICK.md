# ⚡ Быстрые команды SMB3 File Processor

## 🚀 ЗАПУСК С ИНТЕРНЕТОМ
```bash
# Настройка
cp .env.example .env
nano .env  # настроить SMB3 параметры

# Тест SMB3
python test_smb3.py

# Запуск
docker-compose up --build -d

# Проверка
curl http://localhost:3000/health
curl http://localhost:3000/process
```

## 🔒 ЗАПУСК БЕЗ ИНТЕРНЕТА

### На машине с интернетом:
```bash
bash prepare_full_offline.sh
# Копируем smb3-processor-full-offline.tar.gz на целевую машину
```

### На целевой машине:
```bash
tar -xzf smb3-processor-full-offline.tar.gz
cd smb3-processor-full-offline/
cp .env.example .env
nano .env  # настроить SMB3
python test_smb3.py
bash install_full_offline.sh
```

## 🧪 ТЕСТИРОВАНИЕ
```bash
# Health check
curl http://localhost:3000/health

# Обработка файлов
curl http://localhost:3000/process

# Полный тест
python test_local.py

# SMB3 диагностика
python test_smb3.py
```

## 📊 МОНИТОРИНГ
```bash
# Логи
docker-compose logs -f smb-processor

# Статус
docker-compose ps

# Ресурсы
docker stats smb-file-processor-offline
```

## 🔧 УПРАВЛЕНИЕ
```bash
# Остановка
docker-compose down

# Перезапуск
docker-compose restart

# Пересборка
docker-compose up --build -d
```

## 🆘 ДИАГНОСТИКА
```bash
# Проверка SMB3 сервера
ping SMB_HOST
telnet SMB_HOST 445
smbclient -L //SMB_HOST -U USERNAME --max-protocol=SMB3

# Проверка контейнера
docker exec -it smb-file-processor-offline /bin/bash
docker-compose logs --tail=50 smb-processor
```
