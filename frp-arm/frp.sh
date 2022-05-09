#!/bin/bash
echo -e "创建目录"
mkdir /etc/frp
echo -e "进入目录"
cd /etc/frp
echo -e "下载文件"
wget https://raw.githubusercontent.com/whooc/whooc-script/main/frp-arm/frp.tar.gz
echo -e "解压文件"
tar -xzvf frp.tar.gz
echo -e "复制启动文件到系统目录"
cp /etc/frp/systemd/frps.service /etc/systemd/system
cp /etc/frp/systemd/frpc.service /etc/systemd/system
echo -e "进入启动目录并赋予754权限"
cd /etc/systemd/system
chmod 754 frpc.service
chmod 754 frps.service
echo -e "开启自启"
systemctl enable frpc.service
systemctl enable frps.service
echo -e "退回FRP目录"
cd /etc/frp
echo -e "复制启动文件到系统目录"
cp frpc /usr/bin
cp frps /usr/bin
echo -e "赋予权限"
chmod +x /usr/bin/frpc
chmod +x /usr/bin/frps
echo -e "启动文件"
systemctl start frpc
systemctl start frps
echo -e "查询结果"
ps -ef|grep frpc
ps -ef|grep frps