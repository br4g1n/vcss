#!/bin/bash

username='support'
password='elephant'
dir=$(pwd)
file_to_transfer="$dir/mars-saturn.sh"
file="/home/support/mars-saturn.sh"
ip_addresses=("192.0.2.1" "192.0.2.2" "192.0.2.3" "192.0.2.4" "192.0.2.242" "192.0.2.7" "192.0.2.8" "192.0.2.9" "192.0.2.10")

set -e
check_root_privileges() {
# Проверка запускаем ли мы скрипт с Root правами
if [[ ${EUID} -ne 0 ]]; then
    echo "Требуются права суперпользователя"
    exit 1
fi
}
# Проверка есть ли этот адрес в ip a, тк загрузка скрипта подразумевается с левого Сатурна

get_saturn_ip() {
if [[ -z $(ip -br a | grep 192.0.2.5) ]]; then
    echo "Установка обновления подразумевается c Левого Saturn (192.0.2.5)"
    exit 1
fi
}

# Распаковка архива, добавление репозитория в /repo

get_archive() {
sudo tar xf VCSS_14.4.r_build_82_a16se_NoFly_SIGNED.tar -C /
sleep 2
sudo apt-key add /repo/VCSS_14.4.r/repo_key.gpg
sleep 2
if [ -f /etc/astra_update_version ]; then ASTRA_UPDATE_VERSION=`grep Bul /etc/astra_update_version | cut -d" " -f2`; fi
echo "deb file:///repo/VCSS_14.4.r stable main $ASTRA_UPDATE_VERSION" | sudo tee /etc/apt/sources.list.d/VCSS_14.4.r.list
sudo apt-get update
sleep 2
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                   Распаковка архива завершена                @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                   Archive unpacking completed                @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
sleep 5
}

# Установка FTP службы

install_ftp () {
dpkg -i vsftpd_3.0.3-8_amd64.deb
#sudo apt install -y vsftpd

echo "listen=yes
listen_ipv6=no
anonymous_enable=YES
local_enable=no
anon_root=/repo
no_anon_password=yes
hide_ids=yes" >  /etc/vsftpd.conf


sudo systemctl enable vsftpd
sudo systemctl restart vsftpd

#iptables -A INPUT -p tcp --dport 21 -s 192.0.2.0/24 -j ACCEPT
#iptables -A INPUT -p tcp --dport 21 -j DROP
#iptables-save > /etc/iptables-conf/iptables_rules.ipv4
}



#################################################################################################################
#Скрипт для передачи файла, подключения по ssh и запуска скрипта mars-saturn
#################################################################################################################


get_file() {
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@            Проверка сетевой доступности и передача файла     @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
for ip in "${ip_addresses[@]}"
do
    if ping -c 1 $ip &> /dev/null; then
        echo "###|||Ping to $ip успешно. Передача файла...|||###"
        expect -c "
            spawn scp $file_to_transfer $username@$ip:/home/support
            expect {
                \"Password:\" {send \"$password\r\"; interact}
            }
        "
        file_transferred=true
    else
        echo "###|||Ping to $ip failed.|||###"
    fi

    if [ "$file_transferred" = true ]; then
        file_transferred=false  # Сброс флага передачи файла после успешной передачи и подключение к остальным ip адресам
    fi
done
}


function run_with_password {
    expect -c "
    set timeout 30
    spawn $1
    expect \"Password:\"
    send \"$password\n\"
    interact
    "
}

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@             Запуск скрипта mars-saturn                       @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "

start_file() {
for ip in "${ip_addresses[@]}"; do
    run_with_password "ssh $username@$ip \"sudo bash -s\" < \"$file\""
done
}

check_device() {
  if [ -d "/home/protei/Protei-A-SBC" ]; then
  	device_type="Saturn_SBC"
  else
  	device_type="Saturn"
  fi

DATE=$(date +"%Y-%m-%d_%H:%M:%S")
mkdir -p /home/support/VCSS_BACK/${DATE}

 if [ "$device_type" == "Saturn_SBC" ]; then
    cp -r /etc/network /home/support/VCSS_BACK/${DATE}/
    cp -r /etc/protei-auto-setup.d /home/support/VCSS_BACK/${DATE}/protei-auto-setup.d
    cp /etc/apache2/sites-available/webrtc.conf /home/support/VCSS_BACK/${DATE}/
    cp /var/www/html/assets/config/settings.json /home/support/VCSS_BACK/${DATE}/
    cp -r /home/protei/config/Protei-A-SBC /home/support/VCSS_BACK/${DATE}/ 
    cp -r /home/protei/config/Protei-VCS /home/support/VCSS_BACK/${DATE}/
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                   Тип устройства Сатурн с SBC                @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                   Type Saturn with SBC                       @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
 elif [ "$device_type" == "Saturn" ]; then
    cp -r /etc/network /home/support/VCSS_BACK/${DATE}/
    cp -r /etc/protei-auto-setup.d /home/support/VCSS_BACK/${DATE}/protei-auto-setup.d
    cp -r /home/protei/config/Protei-VCS /home/support/VCSS_BACK/${DATE}/
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                   Тип устройства Сатурн                      @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                   Type Saturn                                @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
 fi
}

upgrade_saturn () {
# Обновление пакетов на левом Сатурне
sudo apt update
sudo apt dist-upgrade -y
sleep 2
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                     Левый Сатурн обновлен                    @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                     Saturn updated                           @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "

}

check_version () {
echo 'Обновленные пакеты Левого Сатурна 192.0.2.5' >> dpkg.txt
dpkg -l | grep protei >> dpkg.txt
# Вывод dpkg  версии всех плат
for ip in "${ip_addresses[@]}"; do
    output=$(run_with_password "ssh $username@$ip \"dpkg -l | grep protei\"")
    echo "Вывод команды dpkg на $ip:" >> dpkg.txt
    echo "$output" >> dpkg.txt
done
}

main () {
    check_root_privileges
    get_saturn_ip
    get_archive
    install_ftp
    get_file
    start_file
    check_device
    upgrade_saturn
    check_version
}

main

