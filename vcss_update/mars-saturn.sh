#!/bin/bash

check_root_privileges() {
    if [[ $EUID -ne 0 ]]; then
        echo "Требуются права суперпользователя"
        exit 1
    fi
}

get_saturn_ip() {
    ip -br a | grep 192.0.2.242 > /dev/null && LEFT_SATURN_IP="192.0.2.241" || LEFT_SATURN_IP="192.0.2.5" 
}


get_repos() {
    REPOS=$(curl -s --connect-timeout 10 ftp://${LEFT_SATURN_IP} | grep '^d' | awk '{print $NF}') 
    [[ -z "${REPOS}" ]] && echo "He найдено репозиториев на Saturn ${LEFT_SATURN_IP}" && exit 1
}

# Создаем бэкап и очищаем наш sources.list

backup_and_delete_sources() {
    DATE=$(date +"%Y-%m-%d_%H:%M:%S")
    mkdir -p /etc/apt/backup/${DATE}
    mv /etc/apt/sources.list.d/* /etc/apt/backup/${DATE}
    cp /etc/apt/sources.list /etc/apt/backup/${DATE}/sources.list
    cat /dev/null > /etc/apt/sources.list
    mkdir -p /home/support/VCSS_BACK/${DATE}
}

# Смотрим версию Астры и прописываем ее в sources.list.d, скачиваем repo-key.gpg 

update_sources_and_keys() {
    for REPO in ${REPOS}; do
        case $(cat /etc/issue) in
            *"1.6"*)
                ASTRA_UPDATE_VERSION=$(grep Bul /etc/astra_update_version | cut -d" " -f2)
                ;;
            *"1.7"*)
                ASTRA_UPDATE_VERSION=""
                [[ ${ASTRA_UPDATE_VERSION} != "1.7.3" ]] && ASTRA_UPDATE_VERSION=$(cat /etc/astra_version)
                ;;
            *)
                ASTRA_UPDATE_VERSION=""
                ;;
        esac

        echo "deb ftp://${LEFT_SATURN_IP}/${REPO} stable main ${ASTRA_UPDATE_VERSION}" | sudo tee /etc/apt/sources.list.d/ftp_Saturn_${REPO}.list
        curl ftp://${LEFT_SATURN_IP}/${REPO}/repo_key.gpg | sudo apt-key add -
    done
}

# Создаем бэкап 

#config_backup() {
# DATE=$(date +"%Y-%m-%d_%H:%M:%S")
# 	mkdir -p /home/support/VCSS_BACK/${DATE}
#  	cp /etc/network/interfaces /home/support/VCSS_BACK/${DATE}/interfaces
  
# Проверяем наличие папки MCU.Node в /home/protei/Protei-VCS, благодаря этому узнаем какой тип устройства
check_device() {	
  if [ -d "/home/protei/Protei-VCS/MCU.Node" ]; then
    	device_type="Mars"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                   Тип устройства Mars                        @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                   Type Mars                                  @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
  elif [ -d "/home/protei/Protei-A-SBC" ]; then
  	device_type="Saturn_SBC"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                   Тип устройства Saturn c SBC                @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                   Type Saturn with SBC                       @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
  else 
  	device_type="Saturn"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                   Тип устройства Saturn                      @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                   Type Saturn                                @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
  fi
 
# Копируем соответствующие папки в зависимости от типа устройства
 
 if [ "$device_type" == "Mars" ]; then
	cp -r /home/protei/config/Protei-VCS/MCU.Node /home/support/VCSS_BACK/${DATE}/
 elif [ "$device_type" == "Saturn_SBC" ]; then
    cp -r /etc/network /home/support/VCSS_BACK/${DATE}/
    cp -r /etc/protei-auto-setup.d /home/support/VCSS_BACK/${DATE}/protei-auto-setup.d
    cp /etc/apache2/sites-available/webrtc.conf /home/support/VCSS_BACK/${DATE}/
    cp /var/www/html/assets/config/settings.json /home/support/VCSS_BACK/${DATE}/
    cp -r /home/protei/config/Protei-A-SBC /home/support/VCSS_BACK/${DATE}/ 
    cp -r /home/protei/config/Protei-VCS /home/support/VCSS_BACK/${DATE}/
 elif [ "$device_type" == "Saturn" ]; then
    cp -r /etc/network /home/support/VCSS_BACK/${DATE}/
    cp -r /etc/protei-auto-setup.d /home/support/VCSS_BACK/${DATE}/protei-auto-setup.d
    cp -r /home/protei/config/Protei-VCS /home/support/VCSS_BACK/${DATE}/
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                     Файлы скопированы                        @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                    Files has been copied                     @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
 fi
 
}

config_upgrade() {
sudo apt-get dist-upgrade -y
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                 Обновление на плате завершено                @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@                 The update is complete                       @@ "
echo "@@--------------------------------------------------------------@@ "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ "        
}

main() {
    check_root_privileges
    get_saturn_ip
    get_repos
    backup_and_delete_sources
    update_sources_and_keys
    check_device
    sudo apt update
    config_backup
    config_upgrade
}

main
