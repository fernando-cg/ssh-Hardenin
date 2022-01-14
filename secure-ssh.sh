#!/bin/bash

if (( $EUID != 0 )); then
    echo "Ejecuta el script como root"
    exit
fi

pass=$(date | sha256sum | awk '{print $1}') #pass gen
path=/etc/ssh/sshd_config
port=$(shuf -i 40000-60000 -n 1) #Puerto random

useradd -m -p $pass sssh #Creo un usuario especial para ssh
su sssh -c "ssh-keygen -t rsa -N $pass" <<< "" #Genero una clave rsa cifrada con una password aleatoria
su sssh -c "cat /home/sssh/.ssh/id_rsa.pub > /home/sssh/.ssh/authorized_keys"
su sssh -c "chmod 600 /home/sssh/.ssh/authorized_keys"
mv /home/sssh/.ssh/id_rsa .

#confifuraciones para el servicio ssh

sed -i 's/#Port.*/Port '$port'/' $path #Change Port
sed -i 's/#LoginGraceTime.*/LoginGraceTime 1m/' $path #Change request Time
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' $path #Change root login
sed -i 's/#MaxAuthTries.*/MaxAuthTries 2/' $path #change login tries
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' $path #disable password auth
sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' $path #allow -i flag
sed -i 's/#AllowUsers.*/AllowUsers sssh/' $path #only allow ssh user
sed -i 's/#PermitEmptyPasswords.*/PermitEmptyPasswords no/' $path
sed -i 's/#X11Forwarding.*/X11Forwarding no/' $path #bloquea que no se inicien aplicaciones grafica de escritorio remotamente
sed -i 's/#MaxSessions.*/MaxSessions 5/' $path #cambia max session
sed -i 's/#LogLevel.*/LogLevel INFO/' $path #cambia max session
sed -i 's/#SyslogFacility.*/SyslogFacility local3/' $path

#Configuracion inicial del firewall
echo "A continuacion introduceme un fichero con una lista de ips para hacer una white list"
read diccionario
ufw enable
for i in `cat $diccionario`; do sudo ufw allow from $i to any port $port ;done

#configuracion para la blacklist
mkdir /var/log/sshd
touch /var/log/sshd/sshd.log
echo "local3.* /var/log/sshd/sshd.log" >> /etc/rsyslog.conf
mv blackList.py /root
service rsyslog restart
echo "*/1 * * * * root python3 /root/blackList.py" >> /etc/crontab
service cron restart

echo "El script ha sido completado,La password del fichero y del usuario sssh es:" $pass
echo "La conexion es: ssh sssh@ip -i id_rsa -p " $port
