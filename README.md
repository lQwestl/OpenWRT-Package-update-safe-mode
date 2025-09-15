# 📦 Список и установка обновляемых пакетов OpenWRT / LEDE opkg

Скрипт для упрощения обновления пакетов opkg.

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

Simple OPKG Updater v0.4.1

Usage: opkg-upgrade [options]

Options:
  -V, --version         Show program name and version and exits
  -h, --help            Show this help screen and exits
  -i, --install [dir]   Install opkg-upgrade to [dir] or /usr/sbin
                        Leave [dir] empty for default (/usr/sbin)
  -u, --upgrade-check   Returns SUCCESS if there are updates available
                        Quiet execution, returns 0 or 1
  -l, --list-upgrades   Prints the list of available updates and exits
  -e, --email-list      Prints the list of updates in html email format
                        Includes subject, mime type and html formated data
  -s, --ssmtp <email>   Use the system's ssmtp to send update reports
                        You need to install and configure ssmtp beforehand
  -m, --msmtp <email>   Use the system's msmtp to send update reports
                        You need to install and configure msmtp beforehand
  -a, --always-send     Send e-mail even if there are no updates
                        By default e-mails are only sent when updates are available
  -t, --text-only       Send e-mail in plain text format.
                        By default, e-mails are sent in html format.
  -n, --no-opkg-update  Skip opkg update at the beginning,
                        may not find packages if not up to date
  -f, --force           Do not ask for confirmation,
                        will update everything available

Notes:
  - Short options should not be grouped. You must pass each parameter on its own.
  - You must have a working ssmtp or msmtp install to use the email functionality.
    Make sure you can send e-mails from it before trying from opkg-upgrade.

Examples:
  opkg-upgrade -n -f      # run without updating listings and asking for upgrade
  opkg-upgrade --install  # install to /usr/sbin/opkg-upgrade
  opkg-upgrade -l         # just print upgrades available
  opkg-upgrade -e         # just print html formatted email
  opkg-upgrade -s 'mail@example.com'    # mail upgrade report if have updates
  opkg-upgrade -a -m 'mail@example.com' # mail upgrade report even if NO updates
  opkg-upgrade -u && echo 'upgrades are available' || echo 'no upgrades available'
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
git clone git://github.com/tavinus/opkg-upgrade.git
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
wget 'https://raw.githubusercontent.com/tavinus/opkg-upgrade/master/opkg-upgrade.sh' -O "/tmp/opkg-upgrade.sh" && chmod 755 "/tmp/opkg-upgrade.sh" && /tmp/opkg-upgrade.sh
```

### Локальная установка в текущий каталог
```bash
wget 'https://raw.githubusercontent.com/tavinus/opkg-upgrade/master/opkg-upgrade.sh' -O "opkg-upgrade.sh" && chmod 755 "opkg-upgrade.sh"
```

### Системная установка в `/usr/sbin`
```bash
wget 'https://raw.githubusercontent.com/tavinus/opkg-upgrade/master/opkg-upgrade.sh' -O "/usr/sbin/opkg-upgrade" && chmod 755 "/usr/sbin/opkg-upgrade"
```

---

## 🔗 Полезные ссылки

- [OpenWRT Wiki — wget SSL certs](https://wiki.openwrt.org/doc/howto/wget-ssl-certs)  
- [Форум OpenWRT](https://forum.openwrt.org/viewtopic.php?pid=284368#p284368)  
- [Ticket #19621](https://dev.openwrt.org/ticket/19621)  
