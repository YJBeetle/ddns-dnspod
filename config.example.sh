#目录设定
TMPDIR='/tmp/ddns_dnspod_tempfile'
OLDIPDIR="/tmp/ddns_dnspod_oldip"

#获取本地IP服务器
GETIPV4=('http://api.ipify.org' 'http://icanhazip.com' 'http://ident.me' 'http://whatismyip.akamai.com' 'http://myip.dnsomatic.com' 'http://ifconfig.me' 'http://ipv4.vm0.test-ipv6.com/ip/')
GETIPV6=('http://ipv6.vm0.test-ipv6.com/ip/' 'http://ipv6.test-ipv6.ke.liquidtelecom.net/ip/' 'http://ipv6.test-ipv6.arauc.br/ip/' 'http://ipv6.test-ipv6.cl/ip/' 'http://ipv6.test-ipv6.vyncke.org/ip/')