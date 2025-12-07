#!/bin/sh

echo ">>> 添加 edge 仓库"
cat >> /etc/apk/repositories <<EOF
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF

echo ">>> 更新 APK 索引"
apk update

echo ">>> 安装 shadowsocks-libev"
apk add shadowsocks-libev \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing

echo ">>> 创建 Shadowsocks 配置"
mkdir -p /etc/shadowsocks

cat > /etc/shadowsocks/config.json <<EOF
{
    "server": "::",
    "server_port": 3333,
    "password": "www321654",
    "method": "aes-256-gcm",
    "fast_open": false,
    "timeout": 300,
    "mode": "tcp_and_udp"
}
EOF

echo ">>> 创建 Shadowsocks 服务文件"
cat > /etc/init.d/shadowsocks <<'EOF'
#!/sbin/openrc-run

command="/usr/bin/ss-server"
command_args="-c /etc/shadowsocks/config.json -u"

pidfile="/run/shadowsocks.pid"
command_background="yes"

depend() {
    need net
}
EOF

chmod +x /etc/init.d/shadowsocks
rc-update add shadowsocks
rc-service shadowsocks start

#########################################################
#                 启用 BBR（最佳通用方式）
#########################################################

echo ">>> 开启 BBR"
modprobe tcp_bbr 2>/dev/null

echo "tcp_bbr" >> /etc/modules

sysctl -w net.core.default_qdisc=fq
sysctl -w net.ipv4.tcp_congestion_control=bbr

# 持久化
cat >> /etc/sysctl.conf <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

#########################################################
#      自动获取 IPv6 地址 / 国家信息 / 生成 ss:// 链接
#########################################################

echo ">>> 获取 IPv6 地址"
IPV6_ADDR=$(ip -6 addr show | grep 'scope global' | awk '{print $2}' | cut -d/ -f1 | head -n 1)

if [ -z "$IPV6_ADDR" ]; then
    IPV6_ADDR="::1"
fi

echo ">>> 获取国家名称"
apk add geoip >/dev/null 2>&1
COUNTRY=$(geoiplookup $IPV6_ADDR | awk -F ': ' '{print $2}' | awk -F ',' '{print $2}')

if [ -z "$COUNTRY" ]; then
    COUNTRY="Unknown"
fi

echo ">>> 生成 SS 分享链接（仅 IPv6）"

ENCODED="YWVzLTI1Ni1nY206d3d3MzIxNjU0"
SS_LINK="ss://${ENCODED}@[${IPV6_ADDR}]:3333?#${COUNTRY}"

echo "$SS_LINK" > /root/sslink.txt

echo "-------------------------------------------------------"
echo "安装完成！你的 SS 分享链接如下：（已保存到 /root/sslink.txt）"
echo
echo "$SS_LINK"
echo
echo "-------------------------------------------------------"
