# ssh-banip

ssh-banip 通过nali过滤白名单地理区域IP或IP地址，使用fail2ban自动封禁ssh暴力破解IP地址

自动安装配置 nali/fail2ban, 自动开启crontab定时任务

支持 centos7/debian9 以上操作系统

先修改 banip_ssh.sh中 white_list 白名单参数，设置白名单过滤器，多个值使用| 分割追加.
```bash
white_list="btmp begins|1.2.3.4|5.6.7.8"
or
white_list="btmp begins|1.2.3.4|A省B市C区 D运营商|B市 DX运营商"
```
安装命令
```bash
sudo bash install.sh  
```

国内网络可以自动安装完成，国外网络需要手动下载nali IP地址库qqwry.dat，上传至nali安装目录(默认~/.nali/)
