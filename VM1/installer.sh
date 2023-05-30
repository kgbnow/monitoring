#!/bin/bash
# Установка путей и версий
PROMETHEUS_VERSION="2.44.0"
ALERTMANAGER_VERSION="0.25.0"
NODE_EXPORTER_VERSION="1.5.0"
INSTALL_DIR="/opt"
CONFIG_DIR="$(dirname "$0")" # Директория, содержащая скрипт
VERSION_PLACEHOLDER=@VERSION@

# Создание временной директории
TMP_DIR=$(mktemp -d)

# Функция загрузки и разархивирования
download_and_extract() {
    local url="$1"
    local filename="$2"

    # Загрузка файла
    if ! wget -q "$url" -O "$TMP_DIR/$filename"; then
        echo "Ошибка при загрузке файла: $url"
        return 1
    fi

    # Разархивирование файла
    if ! tar -xf "$TMP_DIR/$filename" -C "$TMP_DIR"; then
        echo "Ошибка при разархивировании файла: $filename"
        return 1
    fi

    local dirname="${filename%.tar.gz}"
    local source_dir="$TMP_DIR/$dirname"
    local destination_dir="$INSTALL_DIR/$dirname"

    # Копирование директории
    if ! cp -r "$source_dir" "$destination_dir"; then
        echo "Ошибка при копировании директории: $source_dir"
        return 1
    fi
}

# Функция проверки наличия сервиса
service_exists() {
    local service_name="$1"
    systemctl is-enabled "$service_name" >/dev/null 2>&1
}

# Функция обновления сервис-файла
update_service() {
    local service_name="$1"
    local service_file="$2"
    local version_value="$3"

    if service_exists "$service_name"; then
        echo "Обновление файла сервиса $service_name"
        systemctl stop "$service_name" || { echo "Ошибка при остановке сервиса $service_name"; return 1; }
        systemctl disable "$service_name" || { echo "Ошибка при отключении сервиса $service_name"; return 1; }
        rm "/etc/systemd/system/$service_file" || { echo "Ошибка при удалении сервис-файла $service_file"; return 1; }
    fi

    # Замена версии в сервис-файле
    sed "s/$VERSION_PLACEHOLDER/$version_value/g" "$service_file" > "/etc/systemd/system/$service_file" || { echo "Ошибка при замене версии в сервис-файле $service_file"; return 1; }

    systemctl daemon-reload
    systemctl enable "$service_name" || { echo "Ошибка при включении сервиса $service_name"; return 1; }
    systemctl start "$service_name" || { echo "Ошибка при запуске сервиса $service_name"; return 1; }
}


# Проверка наличия директории Prometheus с нужной версией в папке установки
if [ ! -d "$INSTALL_DIR/prometheus-$PROMETHEUS_VERSION.linux-amd64" ]; then

# Загрузка и установка Prometheus
prometheus_url="https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz"
prometheus_filename="prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz"
download_and_extract "$prometheus_url" "$prometheus_filename"

# Копирование файла конфигурации Prometheus
cp "$CONFIG_DIR/prometheus.yml" "$INSTALL_DIR/prometheus-$PROMETHEUS_VERSION.linux-amd64/"
cp "$CONFIG_DIR/alert.rules.yml" "$INSTALL_DIR/prometheus-$PROMETHEUS_VERSION.linux-amd64/"

# Обновление сервиса Prometheus
update_service "prometheus.service" "./prometheus.service" "$PROMETHEUS_VERSION"

 # Проверка наличия другой версии Prometheus в папке установки
    other_version_dir=$(find "$INSTALL_DIR" -maxdepth 1 -type d -name "prometheus-*" | grep -v "$PROMETHEUS_VERSION")
    if [ -n "$other_version_dir" ]; then
        # Удаление другой версии Prometheus из папки установки
        echo "Удаление предыдущей версии Prometheus: $other_version_dir"
        rm -rf "$other_version_dir"
    fi

else
    echo "Директория Prometheus с версией $PROMETHEUS_VERSION уже существует в папке установки. Пропуск загрузки и установки."
fi

# Проверка наличия директории Alertmanager с нужной версией в папке установки
if [ ! -d "$INSTALL_DIR/alertmanager-$ALERTMANAGER_VERSION.linux-amd64" ]; then

# Загрузка и установка Alertmanager
alertmanager_url="https://github.com/prometheus/alertmanager/releases/download/v$ALERTMANAGER_VERSION/alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz"
alertmanager_filename="alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz"
download_and_extract "$alertmanager_url" "$alertmanager_filename"

# Копирование файла конфигурации Alertmanager
cp "$CONFIG_DIR/alertmanager.yml" "$INSTALL_DIR/alertmanager-$ALERTMANAGER_VERSION.linux-amd64/"

# Обновление сервиса Alertmanager
update_service "alertmanager.service" "./alertmanager.service" "$ALERTMANAGER_VERSION"

 # Проверка наличия другой версии Alertmanager в папке установки
    other_version_dir=$(find "$INSTALL_DIR" -maxdepth 1 -type d -name "alertmanager-*" | grep -v "$ALERTMANAGER_VERSION")
    if [ -n "$other_version_dir" ]; then
        # Удаление другой версии Alertmanager из папки установки
        echo "Удаление предыдущей версии Alertmanager: $other_version_dir"
        rm -rf "$other_version_dir"
    fi

else
    echo "Alertmanager с версией $ALERTMANAGER_VERSION уже существует в папке установки. Пропуск загрузки и установки."
fi

# Проверка наличия директории Node Exporter с нужной версией в папке установки
if [ ! -d "$INSTALL_DIR/node_exporter-$NODE_EXPORTER.linux-amd64" ]; then

# Загрузка и установка Node Exporter
node_exporter_url="https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"
node_exporter_filename="node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"
download_and_extract "$node_exporter_url" "$node_exporter_filename"

# Обновление сервиса Node Exporter
update_service "node-exporter.service" "./node-exporter.service" "$NODE_EXPORTER_VERSION"

 # Проверка наличия другой версии Node Exporter в папке установки
    other_version_dir=$(find "$INSTALL_DIR" -maxdepth 1 -type d -name "node_exporter-*" | grep -v "$NODE_EXPORTER_VERSION")
    if [ -n "$other_version_dir" ]; then
        # Удаление другой версии Node Exporter из папки установки
        echo "Удаление предыдущей версии Node Exporter: $other_version_dir"
        rm -rf "$other_version_dir"
    fi

else
    echo "Node Exporter с версией $NODE_EXPORTER_VERSION уже существует в папке установки. Пропуск загрузки и установки."
fi

# Удаление временной директории
rm -r "$TMP_DIR"
