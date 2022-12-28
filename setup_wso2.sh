#!/bin/bash

# Instalar WSO2 API Manager 4.0.0 en CentOS 8 | RHEL 8
# Creado por: @crixodia

if [ $# -ne 2 ]; then
    echo "Uso: $0 <path_instalacion> <direccion_ip>"
    echo "Ejemplo: $0 /opt 192.168.1.40"
    exit 1
fi

PATH_INSTALACION=$1
DIRECCION_IP=$2

# Instalar dependencias
wget https://github.com/wso2/product-apim/releases/download/v4.0.0/wso2am-4.0.0.zip
sudo yum install java-11-openjdk-devel -y
sudo echo "export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep java-11-openjdk-)" >> /etc/profile
sudo echo "export PATH=$JAVA_HOME/bin:$PATH" >> /etc/profile

# Configurar JAVA_HOME
JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep java-11-openjdk-)

# Instalar WSO2 API Manager 4.0.0
unzip wso2am-4.0.0.zip -d $PATH_INSTALACION

# Configurar firewall
sudo firewall-cmd --add-port=9443/tcp
sudo firewall-cmd --add-port=9443/udp
sudo firewall-cmd --add-port=8280/tcp
sudo firewall-cmd --add-port=8280/udp
sudo firewall-cmd --add-port=8243/tcp
sudo firewall-cmd --add-port=8243/udp
sudo firewall-cmd --runtime-to-permanent

# Configurar hostname
sudo sed -i 's|hostname = "localhost"|hostname = "'$DIRECCION_IP'"|g' $PATH_INSTALACION/wso2am-4.0.0/repository/conf/deployment.toml

# Habilitar Devportal
sudo sed -i '135s/#//' $PATH_INSTALACION/wso2am-4.0.0/repository/conf/deployment.toml
sudo sed -i '136s/#//' $PATH_INSTALACION/wso2am-4.0.0/repository/conf/deployment.toml

# Crear servicio WSO2 API Manager 4.0.0
echo "[Unit]" > /etc/systemd/system/wso2am.service
echo "Description=WSO2 API Manager Service" >> /etc/systemd/system/wso2am.service
echo "After=syslog.target" >> /etc/systemd/system/wso2am.service
echo "" >> /etc/systemd/system/wso2am.service
echo "[Service]" >> /etc/systemd/system/wso2am.service
echo "Type=forking" >> /etc/systemd/system/wso2am.service
echo "User=root" >> /etc/systemd/system/wso2am.service
echo "Group=root" >> /etc/systemd/system/wso2am.service
echo 'Environment="JAVA_HOME=JAVA_PATH"' >> /etc/systemd/system/wso2am.service
echo "ExecStart=PATH_INSTALACION/wso2am-4.0.0/bin/api-manager.sh start" >> /etc/systemd/system/wso2am.service
echo "ExecStop=PATH_INSTALACION/wso2am-4.0.0/bin/api-manager.sh stop" >> /etc/systemd/system/wso2am.service
echo "Restart=on-failure" >> /etc/systemd/system/wso2am.service
echo "" >> /etc/systemd/system/wso2am.service
echo "[Install]" >> /etc/systemd/system/wso2am.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/wso2am.service

# Reemplzar variables en el servicio
sudo sed -i "s|JAVA_PATH|$JAVA_HOME|g" /etc/systemd/system/wso2am.service
sudo sed -i "s|PATH_INSTALACION|$PATH_INSTALACION|g" /etc/systemd/system/wso2am.service

# Iniciar servicio
sudo systemctl enable wso2am
sudo systemctl start wso2am
sudo systemctl status wso2am

# Comprobar que el servicio se ha iniciado correctamente
if [ $? -eq 0 ]; then
    echo "WSO2 API Manager 4.0.0 instalado correctamente"
else
    echo "WSO2 API Manager 4.0.0 no se ha instalado correctamente"
fi
