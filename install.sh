#!/bin/bash
# 说明：使用nali过滤白名单地理区域IP或IP地址，fail2ban自动封禁ssh暴力破解IP地址；
# 

# default vars
nali_version=v0.5.3
nali_ostype=linux
nali_cpumode=amd64
OS_TYPE=$(uname -s)
OS_CPU_ARCH=$(uname -m)
OS_ID_LIKE=redhat

get_os_release(){
    if [ -f /etc/redhat-release ]; then
        echo "Redhat Linux detected."
        OS_ID_LIKE=redhat
    elif [ -f /etc/debian_version ]; then
        echo "Ubuntu/Debian Linux detected."
        OS_ID_LIKE=debian
    else
        echo "Linux distribution not supported."
        echo "This OS is not supported with this script at present. Sorry."
        exit 1
    fi
}

reset_nali_vars(){
    if [[ ${OS_TYPE} =~ "Linux" ]];then
        nali_ostype=linux
    fi

    if [[ $OS_CPU_ARCH =~ "x86_64" ]];then
        nali_cpumode=amd64
    elif [[ $OS_CPU_ARCH =~ "armv5" ]];then
        nali_cpumode=armv5
    elif [[ $OS_CPU_ARCH =~ "armv6" ]];then
        nali_cpumode=armv6
    elif [[ $OS_CPU_ARCH =~ "armv7" ]];then
        nali_cpumode=armv7
    elif [[ $OS_CPU_ARCH =~ "armv8" ]];then
        nali_cpumode=armv8
    elif [[ $OS_CPU_ARCH =~ "aarch64" ]];then
        nali_cpumode=armv8
    else
        echo "unknown cpu arch, set default x86_64"
        nali_cpumode=amd64
    fi
}

nali_install(){
    reset_nali_vars
    wait
    wget --tries=3 -O ./nali-${nali_ostype}-${nali_cpumode}-${nali_version}.gz  https://github.com/zu1k/nali/releases/download/${nali_version}/nali-${nali_ostype}-${nali_cpumode}-${nali_version}.gz
    wait
    gunzip -d ./nali-${nali_ostype}-${nali_cpumode}-${nali_version}.gz
    wait
    mv nali-* /usr/bin/nali && chmod 0755  /usr/bin/nali
    wait
    nali update
    wait
}

set_fail2ban_config(){
    if [[ $OS_ID_LIKE =~ "debian" ]];then
        logpath=/var/log/auth.log
    else
        logpath=/var/log/secure
    fi

    jail_conf=/etc/fail2ban/jail.conf
    
    grep -r "^bantime.multipliers" ${jail_conf} > /dev/null ||sed -i '/1440 2880/abantime.multipliers = 5 60 1440 43200' ${jail_conf}
    sed -i '40,200 s@^bantime.*@bantime = 1d@' ${jail_conf}
    sed -i '40,200 s@^findtime.*@findtime = 10m@' ${jail_conf}
    sed -i '40,200 s@^maxretry.*@maxretry = 5@' ${jail_conf}
    wait

    sudo cat >> ${jail_conf} <<EOF

[ssh-iptables]
enabled = true
filter = sshd
action = iptables[name=SSH, port=ssh, protocol=tcp]
sendmail-whois[name=SSH, dest=example@mail.com, sender=fail2ban@email.com]
# 发行版
logpath = ${logpath}
# ssh 服务的最大尝试次数
maxretry = 5
EOF
    wait
    fail2ban-server -t > /dev/null ; test_ret=$?
    if [ ! $test_ret -eq 0 ];then
        echo "ERROR: fail2ban config jail.conf test is error !"
        exit 1
    else
    systemctl enable  fail2ban
    systemctl restart fail2ban
    fi

}

ssp_install(){
    # install shell
    [ -f ./banip_ssh.sh ]&& chmod 0755 ./banip_ssh.sh && cp -f ./banip_ssh.sh /usr/local/bin/
    # add crontab job, run job 30 min/per
    crontab -l|grep -v 'bash /usr/local/bin/banip_ssh.sh' | { cat; echo "*/30 * * * * bash /usr/local/bin/banip_ssh.sh"; } | crontab -
}

act_redhat(){
    sudo yum -y install epel-release
    sudo yum -y install fail2ban wget
}

act_debian(){
    sudo apt update -y
    sudo apt -y install fail2ban wget
}

fail2ban_install(){
    if [[ $OS_ID_LIKE =~ "debian" ]];then
        act_debian
    else
        act_redhat
    fi
}

main(){
    get_os_release
    fail2ban_install
    set_fail2ban_config
    nali_install
    ssp_install
}

main