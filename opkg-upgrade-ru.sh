#!/bin/sh
###############################################
# Gustavo Arnosti Neves
#
# Создан: Май / 2017
# Обновлен: Ноя / 2022
#
# Обновление пакетов, перечисленных командой:
# opkg list-upgradable
#
# Выводит список пакетов и запрашивает подтверждение
# Используйте ./opkg-upgrade.sh --help для дополнительной информации
#
# Этот скрипт:
# https://github.com/tavinus/opkg-upgrade


### Инициализация
OPKGUPVERSION="0.4.1"
OPKGBIN="$(command -v opkg 2>/dev/null)"
SSMTPBIN="$(command -v ssmtp 2>/dev/null)"
MSMTPBIN="$(command -v msmtp 2>/dev/null)"
BANNERSTRING="Simple OPKG Updater v$OPKGUPVERSION"
TIMESTAMP="$(date '+%Y/%m/%d %H:%M:%S' 2>/dev/null)"
OPKGUP_INSTALL_DIR='/usr/sbin'
OPENWRT_RELEASE="/etc/openwrt_release"
ROUTER_NAME="$(uname -n)"
HTML_FONT="font-family:'Trebuchet MS', Helvetica, sans-serif;"

### Константы для удобства
TRUE=0
FALSE=1

### Флаги выполнения
QUIET_MODE=$FALSE
CHECK_UPDATES_FLAG=$TRUE
FORCE_FLAG=$FALSE
JUST_CHECK_FLAG=$FALSE
JUST_PRINT_FLAG=$FALSE
SSMTP_SEND_FLAG=$FALSE
MSMTP_SEND_FLAG=$FALSE
SEND_TO=""
ALWAYS_SEND_FLAG=$FALSE
HTML_FORMAT=$TRUE
JUST_PRINT_HTML_FLAG=$FALSE

### Имя этого скрипта
OPKGUP_NAME="$(basename $0)"
OPKGUP_LOCATION="$(readlink -f $0)"

### Переменные выполнения, заполняются позже
PACKS=""
PACKS_NAMES=""
PACKS_COUNT=0




########################### НАЧАЛО ФУНКЦИЙ

# Загружает информацию из /etc/openwrt_release в память
source_release() {
    if is_file "$OPENWRT_RELEASE"; then
        . "$OPENWRT_RELEASE"
    fi
}

# Получает списки пакетов opkg и информацию об обновлениях
opkg_init() {
    check_for_opkg
    if should_run_update; then
        opkg_update
    else
        message_ends "Игнорируем обновление списков пакетов"
    fi
    opkg_upgradable
}

# Основная функция
main() {
    source_release
    print_banner
    opkg_init
    upgrade_check      # может завершить выполнение здесь

    local uplist="$(list_upgrades)"
    if should_send_ssmtp || should_send_msmtp || just_print_html; then
        if opkg_has_update || should_always_send || just_print_html; then
            QUIET_MODE=$FALSE
            local email_data=''
            if is_html_email; then
                email_data="$(print_html_email)"
            else
                email_data="$(print_txt_email "$uplist")"
            fi
            if just_print_html; then
                echo -e "$email_data"
                exit 0
            else
                if should_send_ssmtp; then
                    echo -e "$email_data" | "$SSMTPBIN" "$SEND_TO"
                elif should_send_msmtp; then
                    echo -e "$email_data" | "$MSMTPBIN" "$SEND_TO"
                fi
                exit $?
            fi
        fi
        exit 0
    else
        echo -e "$uplist"
    fi
    just_print && exit 0
    opkg_has_update || { echo '' ; exit 0 ; }
    
    openwrt_is_snapshot && print_snapshot_disclaimer

    if ! no_confirm; then
        if ! confirm_upgrade; then
            echo $'Отменено пользователем!\n'
            exit 3
        fi
    else
        echo ""
    fi
    do_upgrade
    exit $?
}

# Просто проверяет наличие обновлений и завершает работу с кодом:
# 0 - если есть обновления
# 1 - если НЕТ обновлений
# Зависит от флага $JUST_CHECK_FLAG для выполнения
upgrade_check() {
    if just_check; then
        opkg_has_update && exit 0
        exit 1
    fi
}

# Выводит список доступных обновлений,
# возвращает $TRUE если есть обновления, $FALSE если нет
list_upgrades() {
    if opkg_has_update; then
        echo "Пакеты доступные для обновления: $PACKS_COUNT"$'\n'
        print_packs_txt
        return $TRUE
    fi
    echo $'Нет пакетов для установки!\n\n'
    return $FALSE
}

# Выводит информацию о роутере в текстовом формате
print_info_txt() {
                                           printf "%s\n" "Имя роутера.: $ROUTER_NAME"
    is_not_empty "$DISTRIB_DESCRIPTION" && printf "%s\n" "Описание....: $DISTRIB_DESCRIPTION"
    is_not_empty "$DISTRIB_TARGET"      && printf "%s\n" "Цель........: $DISTRIB_TARGET"
    is_not_empty "$DISTRIB_ARCH"        && printf "%s\n" "Архитектура.: $DISTRIB_ARCH"
    echo ""
}

# Красиво выводит списки пакетов в текстовом формате
print_packs_txt() {
    echo "Пакеты доступные для обновления: $PACKS_COUNT"
    echo ""
    echo "┌───────┬──────────────────────────────────────────────────────────────────┬──────────────────────────────────────┬──────────────────────────────────────┐"
    echo "│   #   │ Пакет                                                            │ Текущий                              │ Обновление                           │"
    echo "├───────┼──────────────────────────────────────────────────────────────────┼──────────────────────────────────────┼──────────────────────────────────────┤"
    
    echo -ne "$PACKS" | awk '{
        printf "│ %5d │ %-64s │ %-36s │ %-36s │\n", NR, $1, $3, $5
    }'
    
    echo "└───────┴──────────────────────────────────────────────────────────────────┴──────────────────────────────────────┴──────────────────────────────────────┘"
}

### Разбор параметров командной строки
get_options() {
    while :; do
        case "$1" in
            -V|--version|--Version)
                print_banner 'nopadding' ; exit 0 ;;
            -h|--help|--Help)
                print_help ; exit 0 ;;
            -i|--install)
                self_install "$2" ; exit $? ;;
            -u|--upgrade-check|--upgrade-Check|--upgradecheck|--upgradeCheck)
                QUIET_MODE=$TRUE ; JUST_CHECK_FLAG=$TRUE ; shift ;;
            -l|--list-upgrades|--list-Upgrades|--listupgrades|--listUpgrades)
                QUIET_MODE=$TRUE ; JUST_PRINT_FLAG=$TRUE ; shift ;;
            -e|--email-list|--email-List|--emaillist|--emailList)
                QUIET_MODE=$TRUE ; JUST_PRINT_HTML_FLAG=$TRUE ; shift ;;
            -s|--ssmtp)
                ssmtp_check "$2" ; shift ; shift ;;
            -m|--msmtp)
                msmtp_check "$2" ; shift ; shift ;;
            -a|--always-send|--always-Send|--alwayssend|--alwaysSend)
                ALWAYS_SEND_FLAG=$TRUE ; shift ;;
            -t|--text-only|--text-Only|--textonly|--textOnly)
                HTML_FORMAT=$FALSE ; shift ;;
            -n|--no-pkg-update)
                CHECK_UPDATES_FLAG=$FALSE ; shift ;;
            -f|--force)
                FORCE_FLAG=$TRUE ; shift ;;
            -q|--quiet)
                QUIET_MODE=$TRUE ; shift ;;
            *)
                check_invalid_opts "$1" ; break ;;
        esac
    done
}

# В случае этого скрипта, просто проверяем что у нас пустая строка и все должно быть хорошо
check_invalid_opts() {
    if is_not_empty "$1"; then
        print_banner
        echo "Неверная опция: $1"$'\n'
        exit 2
    fi
    return 0
}



###### ВЫВОД СООБЩЕНИЙ

# выводит сообщение в stderr
print_error() {
    echo "$@" >&2
}

# Выводит предупреждение об обновлении бета/trunk версий
print_snapshot_disclaimer() {
    printf "\n%s\n%s\n%s\n%s\n" "ВНИМАНИЕ! Вы используете Beta / Snapshot / Trunk версию!" "Обновление snapshots МОЖЕТ вызвать нежелательные результаты, включая мягкие блокировки." "Текущая версия trunk может быть несовместима с вашей установленной версией!" "Вы предупреждены! Продолжайте на свой страх и риск!"
}

# выводит название программы и версию
print_banner() {
    [[ "$1" = 'error' ]] && { print_error $'\n'"$BANNERSTRING"$'\n' ; return $TRUE ; }
    is_quiet && ! just_print && return $TRUE
    local str=""
    if [[ "$1" = 'nopadding' ]]; then
        str="$BANNERSTRING"
    else
        str=$'\n'"$BANNERSTRING"$'\n'
    fi
    echo "$str"
}

# выводит справку на экран и завершает работу
print_help() {
    print_banner
    echo "Использование: $OPKGUP_NAME [опции]

Опции:
  -V, --version         Показать название программы и версию и выйти
  -h, --help            Показать эту справку и выйти
  -i, --install [dir]   Установить opkg-upgrade в [dir] или /usr/sbin
                        Оставьте [dir] пустым для значения по умолчанию (/usr/sbin)
  -u, --upgrade-check   Возвращает УСПЕХ, если есть доступные обновления
                        Тихий режим выполнения, возвращает 0 или 1
  -l, --list-upgrades   Выводит список доступных обновлений и выходит
  -e, --email-list      Выводит список обновлений в формате html email
                        Включает тему, mime тип и данные в html формате
  -s, --ssmtp <email>   Использовать системный ssmtp для отправки отчетов об обновлениях
                        Вам нужно установить и настроить ssmtp заранее
  -m, --msmtp <email>   Использовать системный msmtp для отправки отчетов об обновлениях
                        Вам нужно установить и настроить msmtp заранее
  -a, --always-send     Отправлять email даже если нет обновлений
                        По умолчанию email отправляются только при наличии обновлений
  -t, --text-only       Отправлять email в текстовом формате.
                        По умолчанию email отправляются в html формате.
  -n, --no-opkg-update  Пропустить opkg update в начале,
                        может не найти пакеты если не обновлено
  -f, --force           Не запрашивать подтверждение,
                        обновит все доступное

Примечания:
  - Короткие опции не должны группироваться. Вы должны передавать каждый параметр отдельно.
  - У вас должна быть рабочая установка ssmtp или msmtp для использования функциональности email.
    Убедитесь что вы можете отправлять email из него перед попыткой использования с opkg-upgrade.

Примеры:
  $OPKGUP_NAME -n -f      # запустить без обновления списков и запроса подтверждения обновления
  $OPKGUP_NAME --install  # установить в /usr/sbin/opkg-upgrade
  $OPKGUP_NAME -l         # просто вывести доступные обновления
  $OPKGUP_NAME -e         # просто вывести html форматированный email
  $OPKGUP_NAME -s 'mail@example.com'    # отправить отчет об обновлениях если есть обновления
  $OPKGUP_NAME -a -m 'mail@example.com' # отправить отчет об обновлениях даже если НЕТ обновлений
  $OPKGUP_NAME -u && echo 'есть обновления' || echo 'нет обновлений'

"
}

# выводит сообщение на экран с завершающим '\r' для изменения строки позже
message_starts() {
    is_quiet && return $TRUE
    echo -n ".... | $1"$'\r'
}

# выводит сообщение на экран, завершает сообщение задачи
message_ends() {
    is_quiet && return $TRUE
    is_empty "$1" && mess="" || mess="$1"
    echo "Готово | $mess"
}

# проверяет доступен ли у нас opkg
check_for_opkg() {
    if ! is_executable "$OPKGBIN"; then
        print_error $'ОШИБКА! Не удалось найти или запустить бинарник OPKG\n'
        exit 1
    fi
}



##### ОБРАБОТКА ОШИБОК

# Отображает ошибку выполнения и завершает выполнение
rt_exception() {
    local r=1
    is_empty "$2" || r=$2
    print_error "$1"
    exit $r
}



###### OPKG UPDATE И UPGRADEABLE

# обновляет списки пакетов
opkg_update() {
    message_starts "Обновляем списки пакетов"
    local err="$("$OPKGBIN" update 2>&1 >/dev/null)";
    is_empty "$err" || rt_exception $'Ошибка при попытке обновить списки пакетов.\nИнформация для отладки:\n'"$err"
    message_ends
}

# получает список пакетов для обновления
opkg_upgradable() {
    message_starts "Получаем список пакетов для обновления"
    PACKS="$($OPKGBIN list-upgradable | sort | grep -v -e 'marked HOLD or PREFER' -e 'Not selecting')"
    if ! is_empty "$PACKS"; then
        PACKS_NAMES="$(echo -ne "$PACKS" | awk '{ printf "%s ", $1 }')"
        PACKS_COUNT="$(echo "$PACKS" | wc -l)"
    fi
    message_ends
    is_quiet || echo ""
    return $TRUE
}



###### СОЗДАНИЕ EMAIL

# выводит отчет email в html формате
print_html_email() {
    echo "$(email_subject)""$(print_html_mime)""$(print_html_header)""$(print_html_table)""$(print_html_timestamp)"
}

# выводит отчет email в txt формате
print_txt_email() {
    echo "$(email_subject)"$'\n\n'"$(print_banner)"$'\n\n'"$(print_info_txt)"$'\n\n'"$1"$'\n\n'"Сгенерировано: $TIMESTAMP"
}

# выводит html таблицу пакетов
print_html_table() {
    echo '<br>'
    is_empty "$PACKS" && { echo '<br><br><h3 style="'"$HTML_FONT"' font-size:13pt; font-weight:bold">Нет пакетов для установки.</h3>' ; return $TRUE ; }
    local td_padding='padding-left:8px;padding-right:10px;padding-top:12px;padding-bottom:12px;'
    local td_open='<td style=\"'"$td_padding"'\">'
    local th_open='<th style="'"$td_padding"'">'
    echo '<table border="1" width="600px" cellpadding="0" cellspacing="0" style="border-collapse:collapse; '"$HTML_FONT"' font-size:10pt">'
    echo '<tr style="background-color:#2f3263; color:#EEE;" align="left" margin=0 padding=0>'$'\n\t'"$th_open"'#</th>'$'\n\t'"$th_open"'Пакет</th>'$'\n\t'"$th_open"'Текущий</th>'$'\n\t'"$th_open"'Обновление</th>'$'\n''</tr>'
    # большая часть таблицы генерируется с использованием awk
    echo -ne "$PACKS" | \
awk 'BEGIN{ i=1; l=""; } { if (i % 2) l=""; else l=" style=\"background-color:#dedfe8;\""; printf "<tr margin=0 padding=0 align=\"left\"%s>\n\t'"$td_open"'%s</td>\n\t'"$td_open"'%s</td>\n\t'"$td_open"'%s</td>\n\t'"$td_open"'%s</td>\n</tr>\n", l, i++, $1, $3, $5 }'
    echo '</table>'
    return $TRUE
}

# выводит информацию html email
print_html_header() {
    echo $'\n\n''<h2 style="'"$HTML_FONT"' font-size:14pt; margin-top:1.5em; font-weight:bold">'"$(print_banner 'nopadding')"'</h2>'
    echo '<table border="1" width="600px" cellpadding="6pt" cellspacing="0" style="border-collapse:collapse;'"$HTML_FONT"' font-size:11pt">'
    
    echo '<tr><td style="font-weight:bold">Имя роутера</td><td>'"$ROUTER_NAME"'</td></tr>'
    is_not_empty "$DISTRIB_DESCRIPTION" && echo '<tr><td style="font-weight:bold">Описание</td><td>'"$DISTRIB_DESCRIPTION"'</td></tr>'
    is_not_empty "$DISTRIB_TARGET" && echo '<tr><td style="font-weight:bold">Цель</td><td>'"$DISTRIB_TARGET"'</td></tr>'
    is_not_empty "$DISTRIB_ARCH" && echo '<tr><td style="font-weight:bold">Архитектура</td><td>'"$DISTRIB_ARCH"'</td></tr>'
    echo '<tr><td style="font-weight:bold">Количество обновлений</td><td>'"$PACKS_COUNT"'</td></tr>'
    echo '</table>'
}

# выводит mime тип и формат html email
print_html_mime() {
    echo $'\nMIME-Version: 1.0\nContent-Type: text/html; charset=utf-8'
}

# выводит нижний колонтитул информации html email
print_html_timestamp() {
    echo $'\n''<h4 style="'"$HTML_FONT"'">'"Сгенерировано: $TIMESTAMP с помощью "'<a href="https://github.com/tavinus/opkg-upgrade">opkg-upgrade</a></h4>'$'\n'
}

# выводит тему email
email_subject() {
    echo "Subject: opkg-upgrade отчет - $TIMESTAMP"
}



###### ОБНОВЛЕНИЕ

# запрашивает у пользователя подтверждение обновления
confirm_upgrade() {
    read -p $'\nПродолжить обновление? (Y/y для продолжения) ' -n 1 -r
    echo $'\n'
    if [[ "$REPLY" = Y || "$REPLY" = y ]]; then
        return $TRUE
    fi
    return $FALSE
}

# выполняет обновление
do_upgrade() {
    message_starts $'Обновляем пакеты\n\n'
    "$OPKGBIN" install $PACKS_NAMES
    ret=$?
    message_ends $'\nОбновление завершено\n'
    echo $'Пожалуйста, проверьте наличие конфликтов конфигурационных файлов!\n'
    return $ret
}



###### САМОСТОЯТЕЛЬНАЯ УСТАНОВКА

# Находит и копирует себя в целевую локацию и делает исполняемым
self_install() {
    print_banner
    is_empty "$1" || OPKGUP_INSTALL_DIR="$1"
    echo "Текущее расположение: $OPKGUP_LOCATION"
    echo "      Целевая папка: $OPKGUP_INSTALL_DIR"
    if ! is_dir "$OPKGUP_INSTALL_DIR"; then
        print_error $'\n'"Ошибка! Целевая папка не найдена!"
        print_error " -> $OPKGUP_INSTALL_DIR"
        exit 40
    fi
    local t="$OPKGUP_INSTALL_DIR/opkg-upgrade"
    local status="$(cp "$OPKGUP_LOCATION" "$t" 2>&1)"
    if is_not_empty "$status"; then
        print_error "  Не удалось скопировать: $t"
        print_error $'\n'"Ошибка: $status"
        exit 33
    fi
    echo "    Установлен в: $t"
    chmod +x "$t" 2>/dev/null
    [ $? -eq 0 ] && status="OK" || status="Ошибка"
    echo "chmod исполняемый: $status"
    echo $'\nУстановлен успешно, пока!\n'
    exit $?
}



###### ВАЛИДАТОРЫ

# возвращает $TRUE если у нас валидный email адрес, $FALSE в противном случае
is_valid_email() {
    is_empty "$1" && return $FALSE
    local f=$(echo "$1" | grep -E -o "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}$")
    is_empty "$f" && return $FALSE
    return $TRUE
}

# проверяет валидность email или прерывает выполнение
validate_email() {
    if ! is_valid_email "$1"; then
        print_banner 'error'
        print_error "Ошибка! Вы должны указать валидный целевой email адрес!"
        print_error "Неверный адрес -> $1"
        exit 30
    fi
}

# возвращает $TRUE если это валидный файл, $FALSE в противном случае
is_file() {
    [ -f "$1" ] && return $TRUE
    return $FALSE
}

# возвращает $TRUE если это валидная папка, $FALSE в противном случае
is_dir() {
    [ -d "$1" ] && return $TRUE
    return $FALSE
}

# Возвращает $TRUE если файл существует и исполняемый, $FALSE в противном случае
is_executable() {
    [ -f "$1" ] && [ -x "$1" ] && return $TRUE
    return $FALSE
}

# возвращает $TRUE для пустой переменной, $FALSE в противном случае
is_empty() {
    [ -z "$1" ] && return $TRUE
    return $FALSE
}

# возвращает $FALSE для пустой переменной, $TRUE в противном случае
is_not_empty() {
    [ -z "$1" ] && return $FALSE
    return $TRUE
}

# возвращает $TRUE если $PACKS не пустой
opkg_has_update() {
    is_empty "$PACKS" && return $FALSE
    return $TRUE
}

# возвращает $TRUE если $DISTRIB_RELEASE равен SNAPSHOT
openwrt_is_snapshot() {
    [ "$DISTRIB_RELEASE" = "SNAPSHOT" ] && return $TRUE
    return $FALSE
}




###### ФЛАГИ ОПЕРАЦИЙ

# возвращает $TRUE если мы должны использовать HTML формат, $FALSE для TXT формата
is_html_email() {
    return $HTML_FORMAT
}

# возвращает $TRUE если мы выполняемся в тихом режиме, $FALSE в противном случае
is_quiet() {
    return $QUIET_MODE
}

# возвращает $TRUE если мы должны обновлять списки пакетов, $FALSE в противном случае
should_run_update() {
    return $CHECK_UPDATES_FLAG
}

# возвращает $TRUE если мы должны спрашивать пользователя перед обновлением, $FALSE в противном случае
no_confirm() {
    return $FORCE_FLAG
}

# возвращает $TRUE если мы должны просто проверить обновления и выйти, $FALSE в противном случае
just_check() {
    return $JUST_CHECK_FLAG
}

# возвращает $TRUE если мы должны просто вывести список и выйти, $FALSE в противном случае
just_print() {
    return $JUST_PRINT_FLAG
}

# возвращает $TRUE если мы должны отправлять email с помощью ssmtp, $FALSE в противном случае
should_send_ssmtp() {
    return $SSMTP_SEND_FLAG
}

# возвращает $TRUE если мы должны отправлять email с помощью msmtp, $FALSE в противном случае
should_send_msmtp() {
    return $MSMTP_SEND_FLAG
}

# возвращает $TRUE если мы должны отправлять email даже если нет обновлений, $FALSE в противном случае
should_always_send() {
    return $ALWAYS_SEND_FLAG
}

# возвращает $TRUE если мы должны просто вывести html отчет и выйти, $FALSE в противном случае
just_print_html() {
    return $JUST_PRINT_HTML_FLAG
}



###### Функции SSMTP

# Находит и проверяет исполняемый файл ssmtp, возвращает $TRUE если найден, $FALSE в противном случае
find_ssmtp() {
    is_executable "$SSMTPBIN" && return $TRUE
    SSMTPBIN='/usr/sbin/ssmtp'
    is_executable "$SSMTPBIN" && return $TRUE
    return $FALSE
}

# Проверяет программу ssmtp, валидирует целевой email и устанавливает глобальные переменные для emails
ssmtp_check() {
    if ! find_ssmtp; then
        print_banner 'error'
        print_error "Ошибка! Не удалось найти или запустить исполняемый файл SSMTP, убедитесь что он установлен!"
        exit 33
    fi
    validate_email "$1"
    SSMTP_SEND_FLAG=$TRUE
    SEND_TO="$1"
    QUIET_MODE=$TRUE
}


###### Функции MSMTP

# Находит и проверяет исполняемый файл msmtp, возвращает $TRUE если найден, $FALSE в противном случае
find_msmtp() {
    is_executable "$MSMTPBIN" && return $TRUE
    MSMTPBIN='/usr/sbin/msmtp'
    is_executable "$MSMTPBIN" && return $TRUE
    return $FALSE
}

# Проверяет программу msmtp, валидирует целевой email и устанавливает глобальные переменные для emails
msmtp_check() {
    if ! find_msmtp; then
        print_banner 'error'
        print_error "Ошибка! Не удалось найти или запустить исполняемый файл MSMTP, убедитесь что он установлен!"
        exit 34
    fi
    validate_email "$1"
    MSMTP_SEND_FLAG=$TRUE
    SEND_TO="$1"
    QUIET_MODE=$TRUE
}





###### НАЧАЛО ВЫПОЛНЕНИЯ

get_options "$@"
main

exit 20 # сюда никогда не должны попасть
