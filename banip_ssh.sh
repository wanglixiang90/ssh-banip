#!/bin/bash
# 说明：使用nali过滤白名单地理区域IP或IP地址，fail2ban自动封禁ssh暴力破解IP地址；
# 

# vars
logfile=/var/log/banip_ssh.log

# white strings or ip list, '|' split string
white_list="btmp begins|Cogent|加利福尼亚州洛杉矶Cogent通信"

banip_list=($(last -f /var/log/btmp  |nali |grep -Ev "${white_list}" |awk '{print $3}' |sort -n |uniq))

unbanip(){
  sudo fail2ban-client set ssh-iptables unbanip $@
}

banip(){
  sudo fail2ban-client set ssh-iptables banip $@
}

main(){
echo -e "\n#### [ $(date +%F' '%T)] show ssh banip list ####"   |tee -a ${logfile}

# ban ip action
for i in "${banip_list[@]}"
do
  # echo "banip $i"
  banip $i >/dev/null ;ret=$?
  if [ ! $ret -eq 0 ]; then
    echo "WARN: banip $i is failed " |tee -a ${logfile}
  fi
  sleep 0.05
done

sleep 1

# list ban ip
sudo fail2ban-client status ssh-iptables   |tee -a ${logfile}
}

main