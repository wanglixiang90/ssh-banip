#!/bin/bash

# vars
logfile=/var/log/banip_ssh.log

white_list="btmp begins|Cogent|154.3.36.145|加利福尼亚州洛杉矶Cogent通信"

banip_list=($(last -f /var/log/btmp  |nali |grep -Ev "${white_list}" |awk '{print $3}' |sort -n |uniq))

unbanip(){
  sudo fail2ban-client set ssh-iptables unbanip $@
}

banip(){
  sudo fail2ban-client set ssh-iptables banip $@
}

# ban ip action
for i in "${banip_list[@]}"
do
  # echo "banip $i"
  banip $i >/dev/null ;ret=$?
  if [ ! $ret -eq 0 ]; then
    echo "ACT: banip $i is failed " |tee -a ${logfile}
  fi
  sleep 0.1
done

sleep 1

# list ban ip
echo -e "\n#### [ $(date +%F' '%T)] show ssh banip list ####"   |tee -a ${logfile}
sudo fail2ban-client status ssh-iptables   |tee -a ${logfile}
