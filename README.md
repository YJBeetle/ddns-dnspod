# DDNS-Dnspod
利用shell实现的dnspod的DDNS

# 安装
```
cd /usr/local/
git clone https://github.com/YJBeetle/ddns-dnspod.git
cp config.sh.example config.sh
```

用你喜欢的编辑器编辑config.sh文件

其中login_token需要填入在dnspod创建的token

位置在：用户中心 -> 安全设置 -> API Token

快捷链接：https://www.dnspod.cn/console/user/security

domain填入你的域名

record填入你的记录名

# 使用
直接运行

ddns-dnspod.sh

建议搭配cron食用，比如
```
ln -s /usr/local/ddns-dnspod/ddns-dnspod.cron.example /etc/cron.d/ddns-dnspod
```