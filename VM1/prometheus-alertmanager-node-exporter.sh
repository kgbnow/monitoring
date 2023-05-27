#!/bin/bash
wget https://github.com/prometheus/prometheus/releases/download/v2.44.0/prometheus-2.44.0.linux-amd64.tar.gz
wget https://github.com/prometheus/alertmanager/releases/download/v0.25.0/alertmanager-0.25.0.linux-amd64.tar.gz
wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
tar -xf prometheus-2.44.0.linux-amd64.tar.gz
tar -xf alertmanager-0.25.0.linux-amd64.tar.gz
tar -xf node_exporter-1.5.0.linux-amd64.tar.gz
rm prometheus-2.44.0.linux-amd64.tar.gz
rm alertmanager-0.25.0.linux-amd64.tar.gz
rm node_exporter-1.5.0.linux-amd64.tar.gz
mv ./prometheus/* ./prometheus-2.44.0.linux-amd64
mv ./alertmanager/* ./alertmanager-0.25.0.linux-amd64
rm -r ./prometheus
rm -r ./alertmanager
mv ./prometheus.service /etc/systemd/system/
mv ./alertmanager.service /etc/systemd/system/
mv ./node-exporter.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable prometheus.service
systemctl enable alertmanager.service
systemctl enable node-exporter.service
systemctl start prometheus.service
systemctl start alertmanager.service
systemctl start node-exporter.service
