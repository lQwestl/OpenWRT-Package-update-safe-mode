# opkg-upgrade

Простая утилита для обновления пакетов OpenWrt с поддержкой email уведомлений и различных режимов работы.

## Описание

`opkg-upgrade` - это удобный скрипт-обёртка для команды `opkg list-upgradable`, который позволяет:
- Получать список доступных обновлений в удобном табличном формате
- Автоматически обновлять пакеты с подтверждением или без него
- Отправлять отчёты об обновлениях по email в HTML или текстовом формате
- Проверять наличие обновлений программно (для использования в других скриптах)

## Установка

### Автоматическая установка

1. Скачайте скрипт на ваш OpenWrt роутер:
```bash
wget -O opkg-upgrade.sh https://raw.githubusercontent.com/lQwestl/opkg-upgrade/main/opkg-upgrade.sh
```

2. Сделайте скрипт исполняемым:
```bash
chmod +x opkg-upgrade.sh
```

3. Установите в системную директорию (опционально):
```bash
./opkg-upgrade.sh --install
```

Это установит скрипт как `/usr/sbin/opkg-upgrade`.

### Альтернативная установка в другую директорию

```bash
./opkg-upgrade.sh --install /usr/local/bin
```

### Ручная установка

```bash
# Скопируйте скрипт в нужную директорию
cp opkg-upgrade.sh /usr/sbin/opkg-upgrade
chmod +x /usr/sbin/opkg-upgrade
```
### Клонируйте его в текущий каталог и используйте опцию `-i`, чтобы установить его в `/usr/sbin/opkg-upgrade`:
```bash
git clone https://github.com/lQwestl/opkg-upgrade.git
cd opkg-upgrade
chmod +x opkg-upgrade.sh
./opkg-upgrade.sh -i
```

## Основные возможности

### Просмотр доступных обновлений

```bash
# Показать все доступные обновления в табличном формате
opkg-upgrade

# Только список обновлений без интерактивности
opkg-upgrade -l
```

### Автоматическое обновление

```bash
# Обновить все пакеты без подтверждения
opkg-upgrade -f

# Обновить без обновления списков пакетов
opkg-upgrade -n -f
```

### Проверка обновлений программно

```bash
# Проверить наличие обновлений (возвращает 0 если есть, 1 если нет)
opkg-upgrade -u
if [ $? -eq 0 ]; then
    echo "Доступны обновления"
else
    echo "Обновлений нет"
fi
```

### Email уведомления

#### Настройка ssmtp

Установите и настройте ssmtp:
```bash
opkg update
opkg install ssmtp

# Отредактируйте /etc/ssmtp/ssmtp.conf
vi /etc/ssmtp/ssmtp.conf
```

Пример конфигурации для Gmail:
```
root=your.email@gmail.com
mailhub=smtp.gmail.com:587
rewriteDomain=gmail.com
AuthUser=your.email@gmail.com
AuthPass=your_app_password
FromLineOverride=YES
UseSTARTTLS=YES
```

#### Отправка уведомлений

```bash
# Отправить отчет только если есть обновления
opkg-upgrade -s your.email@example.com

# Отправлять отчет всегда (даже если обновлений нет)
opkg-upgrade -a -s your.email@example.com

# Отправить отчет в текстовом формате
opkg-upgrade -t -s your.email@example.com
```

#### Настройка msmtp (альтернатива ssmtp)

```bash
opkg update
opkg install msmtp

# Создайте файл конфигурации
vi ~/.msmtprc
```

Пример конфигурации:
```
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

account        gmail
host           smtp.gmail.com
port           587
from           your.email@gmail.com
user           your.email@gmail.com
password       your_app_password

account default : gmail
```

Использование с msmtp:
```bash
opkg-upgrade -m your.email@example.com
```

## Опции командной строки

| Опция | Длинная версия | Описание |
|-------|----------------|----------|
| `-V` | `--version` | Показать версию программы |
| `-h` | `--help` | Показать справку |
| `-i [dir]` | `--install [dir]` | Установить в указанную директорию (по умолчанию `/usr/sbin`) |
| `-u` | `--upgrade-check` | Проверить наличие обновлений (возвращает код 0/1) |
| `-l` | `--list-upgrades` | Показать список обновлений и выйти |
| `-e` | `--email-list` | Показать HTML-отчет для email |
| `-s <email>` | `--ssmtp <email>` | Отправить отчет через ssmtp |
| `-m <email>` | `--msmtp <email>` | Отправить отчет через msmtp |
| `-a` | `--always-send` | Отправлять email даже без обновлений |
| `-t` | `--text-only` | Отправлять email в текстовом формате |
| `-n` | `--no-opkg-update` | Пропустить обновление списков пакетов |
| `-f` | `--force` | Обновить без подтверждения |
| `-q` | `--quiet` | Тихий режим работы |

## Примеры использования

### Ежедневная проверка обновлений

Добавьте в crontab для ежедневной проверки:
```bash
# Редактировать crontab
crontab -e

# Добавить строку для проверки каждый день в 6:00
0 6 * * * /usr/sbin/opkg-upgrade -s admin@example.com
```

### Автоматическое обновление

Для автоматического обновления без подтверждения:
```bash
# Каждое воскресенье в 3:00
0 3 * * 0 /usr/sbin/opkg-upgrade -n -f
```

### Скрипт для проверки и уведомления

```bash
#!/bin/sh
# check-updates.sh

if /usr/sbin/opkg-upgrade -u; then
    echo "Найдены обновления, отправляем уведомление..."
    /usr/sbin/opkg-upgrade -s admin@example.com
    echo "Уведомление отправлено"
else
    echo "Обновлений не найдено"
fi
```

### Интеграция с системами мониторинга

```bash
#!/bin/sh
# monitoring-check.sh

UPDATES_COUNT=$(/usr/sbin/opkg-upgrade -l | grep -c "│")
echo "opkg_updates_available $UPDATES_COUNT"

# Для Prometheus node_exporter textfile collector
echo "opkg_updates_available $UPDATES_COUNT" > /var/lib/node_exporter/textfile_collector/opkg_updates.prom
```

## Безопасность

⚠️ **Важные предупреждения:**

1. **Snapshot версии**: При использовании snapshot/trunk версий OpenWrt автоматические обновления могут привести к нестабильности системы.

2. **Конфликты конфигураций**: После обновления всегда проверяйте наличие конфликтов конфигурационных файлов.

3. **Резервные копии**: Рекомендуется создавать резервные копии конфигурации перед массовыми обновлениями.

## Требования

- OpenWrt с установленным `opkg`
- Для email уведомлений: `ssmtp` или `msmtp`
- Bash или совместимая оболочка

## Поддерживаемые версии

- OpenWrt 19.07 и новее
- LEDE 17.01 и новее

## Устранение неполадок

### Ошибки email

1. **"Не удалось найти SSMTP"**:
   ```bash
   opkg update
   opkg install ssmtp
   ```

2. **Проблемы с отправкой**:
   - Проверьте настройки в `/etc/ssmtp/ssmtp.conf`
   - Убедитесь что используете пароль приложения для Gmail
   - Проверьте подключение к интернету

### Ошибки обновления

1. **"Ошибка при попытке обновить списки пакетов"**:
   - Проверьте подключение к интернету
   - Убедитесь что репозитории доступны

2. **Конфликты пакетов**:
   - Проверьте `/etc/opkg.conf`
   - Освободите место на устройстве
