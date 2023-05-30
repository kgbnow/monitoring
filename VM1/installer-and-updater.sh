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

    wget -q "$url" -O "$TMP_DIR/$filename"

    tar -xf "$TMP_DIR/$filename" -C "$TMP_DIR"

    local dirname="${filename%.tar.gz}"
    cp -r "$TMP_DIR/$dirname" "$INSTALL_DIR"
}

# Функция проверки наличия сервиса
service_exists() {
    local service_name="$1"
    systemctl is-enabled "$service_name" >/dev/null 2>&1
}

# Функция обновления сервиса
update_service() {
    local service_name="$1"
    local service_file="$2"
    local version_value="$3"

    if service_exists "$service_name"; then
        echo "Обновление сервиса $service_name"
        systemctl stop "$service_name"
        systemctl disable "$service_name"
        rm "/etc/systemd/system/$service_file"
    fi

    # Замена версии в сервис-файле
    sed "s/$VERSION_PLACEHOLDER/$version_value/g" "$service_file" > "/etc/systemd/system/$service_file"

    systemctl daemon-reload
    systemctl enable "$service_name"
    systemctl start "$service_name"
}

# Загрузка и установка Prometheus
prometheus_url="https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz"
prometheus_filename="prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz"
download_and_extract "$prometheus_url" "$prometheus_filename"

# Копирование файла конфигурации Prometheus
cp "$CONFIG_DIR/prometheus.yml" "$INSTALL_DIR/prometheus-$PROMETHEUS_VERSION.linux-amd64/"
cp "$CONFIG_DIR/alert.rules.yml" "$INSTALL_DIR/prometheus-$PROMETHEUS_VERSION.linux-amd64/"

# Обновление сервиса Prometheus
update_service "prometheus.service" "./prometheus.service" "$PROMETHEUS_VERSION"

# Загрузка и установка Alertmanager
alertmanager_url="https://github.com/prometheus/alertmanager/releases/download/v$ALERTMANAGER_VERSION/alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz"
alertmanager_filename="alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz"
download_and_extract "$alertmanager_url" "$alertmanager_filename"

# Копирование файла конфигурации Alertmanager
cp "$CONFIG_DIR/alertmanager.yml" "$INSTALL_DIR/alertmanager-$ALERTMANAGER_VERSION.linux-amd64/"

# Обновление сервиса Alertmanager
update_service "alertmanager.service" "./alertmanager.service" "$ALERTMANAGER_VERSION"

# Загрузка и установка Node Exporter
node_exporter_url="https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"
node_exporter_filename="node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz"
download_and_extract "$node_exporter_url" "$node_exporter_filename"

# Обновление сервиса Node Exporter
update_service "node-exporter.service" "./node-exporter.service" "$NODE_EXPORTER_VERSION"

# Удаление временной директории
rm -r "$TMP_DIR"
