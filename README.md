# DDNS-Dnspod
利用shell实现的dnspod的DDNS

# 安装
克隆至本地，一般来说按我的习惯是克隆到/usr/local/ddns-dnspod

然后

cp config.sh.example config.sh

编辑config.sh

其中login_token需要填入在dnspod创建的token

位置在：用户中心 -> 安全设置 -> API Token

快捷链接：https://www.dnspod.cn/console/user/security

domain填入你的域名

record填入你的记录名

# 使用
直接运行

ddns-dnspod.sh

建议搭配cron食用，比如

ln -s /usr/local/ddns-dnspod/ddns-dnspod.cron.example /etc/cron.d/ddns-dnspod
