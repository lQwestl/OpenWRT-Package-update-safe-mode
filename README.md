# 📦 Список и установка обновляемых пакетов OpenWRT / LEDE opkg

Скрипт для упрощения обновления пакетов opkg. Взят из https://github.com/tavinus/opkg-upgrade

---

## ⚠️ Важные предупреждения

- После обновления следует проверить, нет ли конфликтов в конфигурации!  
- Перед установкой убедитесь, что на корневом диске достаточно места!  
- В скрипте **нет поддержки SSL** для `curl/wget`.  
- Нужно свободное место для загрузки и установки пакетов!  

Если вы используете **основную ветку OpenWRT (snapshots/dev/trunk)**, вам **НЕ следует обновляться** до версии для разработчиков — это может привести к отвалу устройства.  
В случае с `dev/trunk` лучше сделать резервную копию и выполнить полную установку более свежей версии.  
Для **релизов** обновление наоборот рекомендуется (исправления безопасности, багфиксы).

---

## 📖 Пример справки

```bash
root@OpenWrt:~# opkg-upgrade --help

Простой инструмент для обновления OPKG v0.4.1

Использование: opkg-upgrade [параметры]

Параметры:
  -V, --version         Показать название и версию программы и завершить работу
  -h, --help            Показать это справочное окно и завершить работу
  -i, --install [dir]   Установить opkg-upgrade в [dir] или /usr/sbin
                        Оставьте [dir] пустым для использования по умолчанию (/usr/sbin)
  -u, --upgrade-check   Возвращает SUCCESS, если доступны обновления
                        Тихое выполнение, возвращает 0 или 1
  -l, --list-upgrades   Выводит список доступных обновлений и завершает работу
  -e, --email-list      Выводит список обновлений в формате HTML для отправки по электронной почте
                        Включает тему, тип MIME и данные в формате HTML
  -s, --ssmtp <email>   Используйте системный ssmtp для отправки отчётов об обновлениях
                        Вам нужно предварительно установить и настроить ssmtp
  -m, --msmtp <email>   Используйте системный msmtp для отправки отчётов об обновлениях
                        Вам нужно предварительно установить и настроить msmtp
  -a, --always-send     Отправляйте электронное письмо, даже если обновлений нет
                        По умолчанию электронные письма отправляются только при наличии обновлений
  -t, --отправка электронной почты только в текстовом формате.
                        По умолчанию электронные письма отправляются в формате html.
  -n, --no-opkg-update Пропустить обновление opkg в начале,
если оно не обновлено, пакеты могут не обнаруживаться.
  -f, --force Не запрашивает подтверждения,
обновит все доступные

Записи:
  - Короткие варианты не следует группировать. Каждый параметр необходимо указывать отдельно.
  - Для использования функций электронной почты необходимо установить ssmtp или msmtp.
    Прежде чем пытаться использовать opkg-upgrade, убедитесь, что вы можете отправлять электронные письма.

 Примеры:
  opkg-upgrade -n -f      # запуск без обновления списков и запроса на обновление
  opkg-upgrade --install  # установка в /usr/sbin/opkg-upgrade
  opkg-upgrade -l         # просто выводит список доступных обновлений
  opkg-upgrade -e         # просто выводит электронное письмо в формате HTML
  opkg-upgrade -s 'mail@example.com'    # отправляет отчёт об обновлении по электронной почте, если есть обновления
  opkg-upgrade -a -m 'mail@example.com' # отправляет отчёт об обновлении по электронной почте, даже если обновлений нет
  opkg-upgrade -u && echo 'доступны обновления' || echo 'обновлений нет'
```

---

## ▶️ Пример запуска

```bash
root@OpenWrt:~# opkg-upgrade

Simple OPKG Updater v0.4.0

Done | Updating package lists
Done | Getting upgradable packages list

Packages available for upgrade: 28

+-----+----------------------------+--------------------------+--------------------------+
|   # | Package                    | Current                  | Update                   |
+-----+----------------------------+--------------------------+--------------------------+
|   1 | cgi-io                     | 2021-09-08-98cef9dd-20   | 2022-08-10-901b0f04-21   |
|   2 | curl                       | 7.82.0-2                 | 7.83.1-4.1               |
... и так далее ...
```

👉 В конце будет предупреждение:
```
Please check for config file conflicts!
```

---

## 🔁 Повторный запуск

```bash
# ./opkg-upgrade.sh -f -n
```

Если все пакеты обновлены, вывод будет:
```
No packages to install!
```

⚠️ ВАЖНО: Скрипт нужно запускать **3–4 раза**, иначе не все пакеты обновятся!

---

## 🛠️ Установка

### Через Git
```bash
git clone https://github.com/lQwestl/opkg-upgrade.git
cd opkg-upgrade
./opkg-upgrade.sh -i
```

### Через curl/wget
⚠️ `curl` / `wget` могут не работать из-за SSL. В таком случае:
- используйте `curl -k` или `wget --no-check-certificate`
- или установите сертификаты.

```bash
opkg install ca-certificates openssl-util
```

Если всё ещё не работает:
```bash
mkdir -p -m0755 /etc/ssl/certs && curl -k -o /etc/ssl/certs/ca-certificates.crt -L http://curl.haxx.se/ca/cacert.pem
```

---

## 📌 Однострочники

### Запуск из `/tmp`
```bash
# using wget with SSL
wget 'https://raw.githubusercontent.com/lQwestl/opkg-upgrade.sh/main/opkg-upgrade.sh' -O "/tmp/opkg-upgrade.sh" && chmod 755 "/tmp/opkg-upgrade.sh" && /tmp/opkg-upgrade.sh

# using wget WITHOUT SSL
wget --no-check-certificate 'https://raw.githubusercontent.com/lQwestl/opkg-upgrade.sh/main/opkg-upgrade.sh' -O "/tmp/opkg-upgrade.sh" && chmod 755 "/tmp/opkg-upgrade.sh" && /tmp/opkg-upgrade.sh

# using curl with SSL
curl -L 'https://raw.githubusercontent.com/lQwestl/opkg-upgrade.sh/main/opkg-upgrade.sh' -o "/tmp/opkg-upgrade.sh" && chmod 755 "/tmp/opkg-upgrade.sh" && /tmp/opkg-upgrade.sh

# using curl WITHOUT SSL
curl -k -L 'https://raw.githubusercontent.com/lQwestl/opkg-upgrade.sh/main/opkg-upgrade.sh' -o "/tmp/opkg-upgrade.sh" && chmod 755 "/tmp/opkg-upgrade.sh" && /tmp/opkg-upgrade.sh
```

### Локальная установка в текущий каталог
Запустите с помощью ./opkg-upgrade.sh после загрузки
```bash
# using wget with SSL
wget 'https://raw.githubusercontent.com/lQwestl/opkg-upgrade.sh/main/opkg-upgrade.sh' -O "opkg-upgrade.sh" && chmod 755 "opkg-upgrade.sh"

# using wget WITHOUT SSL
wget --no-check-certificate 'https://raw.githubusercontent.com/lQwestl/opkg-upgrade.sh/main/opkg-upgrade.sh' -O "opkg-upgrade.sh" && chmod 755 "opkg-upgrade.sh"

# using curl with SSL
curl -L 'https://raw.githubusercontent.com/lQwestl/opkg-upgrade.sh/main/opkg-upgrade.sh' -o "opkg-upgrade.sh" && chmod 755 "opkg-upgrade.sh"

# using curl WITHOUT SSL
curl -k -L 'https://raw.githubusercontent.com/lQwestl/opkg-upgrade.sh/main/opkg-upgrade.sh' -o "opkg-upgrade.sh" && chmod 755 "opkg-upgrade.sh"
```

### Системная установка в `/usr/sbin/opkg-upgrade (без расширения .sh)`:
Запустите с помощью opkg-upgrade после загрузки
```bash
# using wget with SSL
wget 'https://raw.githubusercontent.com/lQwestl/opkg-upgrade.sh/main/opkg-upgrade.sh' -O "/usr/sbin/opkg-upgrade" && chmod 755 "/usr/sbin/opkg-upgrade"

# using wget WITHOUT SSL
wget --no-check-certificate 'https://raw.githubusercontent.com/lQwestl/opkg-upgrade.sh/main/opkg-upgrade.sh' -O "/usr/sbin/opkg-upgrade" && chmod 755 "/usr/sbin/opkg-upgrade"

# using curl with SSL
curl -L 'https://raw.githubusercontent.com/lQwestl/opkg-upgrade.sh/main/opkg-upgrade.sh' -o "/usr/sbin/opkg-upgrade" && chmod 755 "/usr/sbin/opkg-upgrade"

# using curl WITHOUT SSL
curl -k -L 'https://raw.githubusercontent.com/lQwestl/opkg-upgrade.sh/main/opkg-upgrade.sh' -o "/usr/sbin/opkg-upgrade" && chmod 755 "/usr/sbin/opkg-upgrade"
```
## 🔗 Полезные ссылки

- [OpenWRT Wiki — wget SSL certs](https://wiki.openwrt.org/doc/howto/wget-ssl-certs)  
- [Форум OpenWRT](https://forum.openwrt.org/viewtopic.php?pid=284368#p284368)  
- [Ticket #19621](https://dev.openwrt.org/ticket/19621)  
