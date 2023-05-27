#!/bin/bash
apt update
apt install nginx -y
mv ./default /etc/nginx/sites-available/
wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.11.0/nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
tar -xf nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
tar -xf node_exporter-1.5.0.linux-amd64.tar.gz
rm nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
rm node_exporter-1.5.0.linux-amd64.tar.gz
apt-get install -y adduser libfontconfig1
wget https://dl.grafana.com/oss/release/grafana_9.5.2_amd64.deb
dpkg -i grafana_9.5.2_amd64.deb
mv ./node-exporter.service /etc/systemd/system/
mv ./nginx-exporter.service /etc/systemd/system/
rm grafana_9.5.2_amd64.deb
systemctl daemon-reload
systemctl enable grafana-server
systemctl enable node-exporter.service
systemctl enable nginx-exporter.service
systemctl start grafana-server
systemctl start node-exporter.service
systemctl start nginx-exporter.service
