# 🚀 Быстрый старт SMB3 File Processor

## 🎯 Для машин БЕЗ интернета (рекомендуется)

### На машине с интернетом:
```bash
# 1. Подготовьте все offline пакеты
bash prepare_full_offline.sh

# 2. Скопируйте архив на целевую машину
# Будет создан: smb3-processor-full-offline.tar.gz (~500MB-1GB)
```

### На целевой машине (без интернета):
```bash
# 1. Распакуйте
tar -xzf smb3-processor-full-offline.tar.gz
cd smb3-processor-full-offline/

# 2. Настройте SMB3
cp .env.example .env
nano .env  # укажите ваши SMB3 параметры

# 3. Проверьте подключение
python test_smb3.py

# 4. Запустите
bash install_full_offline.sh
```

## 🌐 Для машин С интернетом

```bash
# 1. Настройте окружение
cp .env.example .env
nano .env  # укажите ваши SMB3 параметры

# 2. Проверьте подключение
python test_smb3.py

# 3. Запустите с Docker
docker-compose up --build -d
```

## ⚙️ Настройка .env файла

```env
# ОБЯЗАТЕЛЬНЫЕ параметры для SMB3
SMB_HOST=192.168.1.100           # IP SMB3 сервера
SMB_SHARE=shared_folder          # Имя SMB3 шары
SMB_USERNAME=your_username       # Пользователь
SMB_PASSWORD=your_password       # Пароль
SMB_DOMAIN=WORKGROUP            # Домен

# API для отправки изображений
API_URL=http://api-server:8080/api/process

# Папки на SMB3 шаре
SMB_INPUT_DIR=input             # Входящие изображения
SMB_OUTPUT_DIR=output           # Обработанные изображения
```

## 🔍 Проверка работы

```bash
# Health check
curl http://localhost:3000/health

# Обработка файлов
curl http://localhost:3000/process

# Логи
docker-compose logs -f  # или docker-compose -f docker-compose.offline.yml logs -f
```

## ⚠️ Важные требования

- **Только SMB3 протокол** (SMB 1.x/2.x не поддерживаются)
- Подписание сообщений должно быть включено на сервере
- Папки `input` и `output` должны существовать на SMB3 шаре
- Пользователь должен иметь права чтения/записи

## 🛠️ Устранение неполадок

### SMB3 проблемы:
```bash
# Проверка поддержки SMB3
smbclient -L //SMB_HOST -U SMB_USERNAME --max-protocol=SMB3

# Тест подключения
python test_smb3.py
```

### Docker проблемы:
```bash
# Перезапуск
docker-compose restart

# Логи
docker-compose logs -f smb-processor
```

## 📞 Быстрая помощь

1. **Сервис не стартует** → Проверьте `docker-compose logs`
2. **SMB3 не подключается** → Запустите `python test_smb3.py`
3. **Нет файлов для обработки** → Проверьте папку `input` на SMB3 шаре
4. **API недоступен** → Проверьте `API_URL` в .env файле

## 🎉 Готово!

После успешного запуска:
- Сервис работает на http://localhost:3000
- Автоматически обрабатывает изображения из SMB3 шары
- Использует только безопасный SMB3 протокол
- Работает полностью автономно без интернета
