#!/usr/bin/env bash

read_xml_dom() {
    local IFS=\> #字段分割符改为>
    read -d \< ENTITY CONTENT #read分隔符改为<
    local ret=$?
    
    if [[ $ENTITY =~ ^[[:space:]]*$ ]] && [[ $CONTENT =~ ^[[:space:]]*$ ]]; then
        return $ret
    fi

    if [[ "$ENTITY" =~ ^\?xml[[:space:]]*(.*)\?$ ]]; then #使用正则去除问号和xml字符
        ENTITY=''
        return 0
    elif [[ "$ENTITY" = \!\[CDATA\[*\]\] ]]; then #CDATA
        CONTENT=${ENTITY}
        CONTENT=${CONTENT#*![CDATA[}
        CONTENT=${CONTENT%]]*}
        ENTITY="![CDATA]"
        return 0
    elif [[ "$ENTITY" = \!--*-- ]]; then #注释
        return 0
    else #普通节点
        if [[ "$ENTITY" = /* ]]; then #节点末尾
            DOMLVL=$[$DOMLVL - 1] #节点等级-1
            return 0
        elif [[ "$ENTITY" = */ ]]; then #节点没有子节点
            :
        elif [ ! "$ENTITY" = '' ]; then #新节点
            DOMLVL=$[$DOMLVL + 1] 
        fi
    fi

    return $ret
}


get_localip_curl()
{
    ip=$(curl "$1" 2>/dev/null)
    ip=$(echo "$ip" | grep -oE "(((\d{1,2})|(1\d{2})|(2[0-4]\d)|(25[0-5]))\.){3}((\d{1,2})|(1\d{2})|(2[0-4]\d)|(25[0-5]))")
    if [ "$ip" = '' ]; then
        return -1
    fi
    echo "$ip"
}

get_localip()
{
    get_localip_curl 'api.ipify.org' ||
    get_localip_curl 'icanhazip.com' ||
    get_localip_curl 'ident.me' ||
    get_localip_curl 'whatismyip.akamai.com' ||
    get_localip_curl 'myip.dnsomatic.com' ||
    get_localip_curl 'ifconfig.me' ||
    return -1
}

get_localip_curl_v6()
{
    ip=$(curl "$1" 2>/dev/null)
    ip=$(echo "$ip" | grep -oE "((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?")
    if [ "$ip" = '' ]; then
        return -1
    fi
    echo "$ip"
}

get_localip_v6()
{
    get_localip_curl_v6 'http://ipv6.vm0.test-ipv6.com/ip/' ||
    get_localip_curl_v6 'http://ipv6.test-ipv6.ke.liquidtelecom.net/ip/' ||
    get_localip_curl_v6 'http://ipv6.test-ipv6.arauc.br/ip/' ||
    get_localip_curl_v6 'http://ipv6.test-ipv6.cl/ip/' ||
    get_localip_curl_v6 'http://ipv6.test-ipv6.vyncke.org/ip/' ||
    return -1
}


get_domain_id()
{
    login_token=$1
    domain=$2

    local DOMLVL=0 #初始化节点
    curl -k https://dnsapi.cn/Domain.List -d "login_token=$login_token" 2>/dev/null > ${TMPDIR}/get_domain_id.xml
    while read_xml_dom; do
        if [ "$ENTITY" = 'item' ]; then
            itemlevel=$DOMLVL
            id=''
            name=''
        fi
        if [[ "$ENTITY" = '/item' ]] && [[ $DOMLVL < $itemlevel ]] ; then
            id=''
            name=''
        fi
        if [[ "$ENTITY" = 'id' ]] || [[ "$ENTITY" = 'name' ]]; then
            if [ "$ENTITY" = 'id' ]; then
                id="$CONTENT"
            fi
            if [ "$ENTITY" = 'name' ]; then
                name="$CONTENT"
            fi
            if [ "$name" = "$domain" ]; then
                okid="$id";
            fi
        fi
        if [ "$ENTITY" = 'code' ]; then
            code="$CONTENT"
        fi
        if [ "$ENTITY" = 'message' ]; then
            message="$CONTENT"
        fi
    done < ${TMPDIR}/get_domain_id.xml

    if [ "$code" = '1' ]; then
        echo "$okid";
        return 0;
    else
        echo "$message";
        return $code;
    fi
}

get_record_id()
{
    login_token=$1
    domain_id=$2
    record=$3
    record_type=$4

    local DOMLVL=0 #初始化节点
    id=''
    name=''
    okid=''
    curl -k https://dnsapi.cn/Record.List -d "login_token=$login_token&domain_id=$domain_id&record_type=$record_type" 2>/dev/null > ${TMPDIR}/get_record_id.xml
    while read_xml_dom; do
        if [ "$ENTITY" = 'item' ]; then
            itemlevel=$DOMLVL
            id=''
            name=''
        fi
        if [[ "$ENTITY" = '/item' ]] && [[ $DOMLVL < $itemlevel ]] ; then
            id=''
            name=''
        fi
        if [[ "$ENTITY" = 'id' ]] || [[ "$ENTITY" = 'name' ]]; then
            if [ "$ENTITY" = 'id' ]; then
                id=$CONTENT
            fi
            if [ "$ENTITY" = 'name' ]; then
                name=$CONTENT
            fi
            if [ "$name" = "$record" ]; then
                okid=$id;
            fi
        fi
        if [ "$ENTITY" = 'code' ]; then
            code=$CONTENT
        fi
        if [ "$ENTITY" = 'message' ]; then
            message="$CONTENT"
        fi
    done < ${TMPDIR}/get_record_id.xml

    if [ "$code" = '1' ]; then
        echo "$okid";
        return 0;
    elif [ "$code" = '10' ]; then
        echo "";
        return 0;
    else
        echo "$message";
        return $code;
    fi
}

create_record()
{
    login_token=$1
    domain_id=$2
    record=$3
    record_type=$4
    value=$5

    local DOMLVL=0 #初始化节点

    curl -k https://dnsapi.cn/Record.Create -d "login_token=$login_token&domain_id=$domain_id&sub_domain=$record&record_type=$record_type&record_line=默认&value=$value" 2>/dev/null > ${TMPDIR}/create_record.xml
    while read_xml_dom; do
        if [ "$ENTITY" = 'id' ]; then
            id="$CONTENT"
        fi
        if [ "$ENTITY" = 'code' ]; then
            code=$CONTENT
        fi
        if [ "$ENTITY" = 'message' ]; then
            message="$CONTENT"
        fi
    done < ${TMPDIR}/create_record.xml

    if [ "$code" = '1' ]; then
        echo "$id";
        return 0;
    else
        echo "$message";
        return $code;
    fi
}

ddns_record()
{
    login_token=$1
    domain_id=$2
    record_id=$3
    record=$4

    local DOMLVL=0 #初始化节点

    curl -k https://dnsapi.cn/Record.Ddns -d "login_token=$login_token&domain_id=$domain_id&record_id=$record_id&sub_domain=$record&record_line=默认" 2>/dev/null > ${TMPDIR}/create_ddns.xml
    while read_xml_dom; do
        if [ "$ENTITY" = 'value' ]; then
            value="$CONTENT"
        fi
        if [ "$ENTITY" = 'code' ]; then
            code=$CONTENT
        fi
        if [ "$ENTITY" = 'message' ]; then
            message="$CONTENT"
        fi
    done < ${TMPDIR}/create_ddns.xml

    if [ "$code" = '1' ]; then
        echo "$value";
        return 0;
    else
        echo "$message";
        return $code;
    fi
}

ddns_record_v6()
{
    login_token=$1
    domain_id=$2
    record_id=$3
    record_v6=$4
    ipv6=$5

    local DOMLVL=0 #初始化节点

    curl -k https://dnsapi.cn/Record.Modify -d "login_token=$login_token&domain_id=$domain_id&record_id=$record_id&sub_domain=$record_v6&record_type=AAAA&record_line=默认&value=$ipv6" 2>/dev/null > ${TMPDIR}/create_ddns.xml
    while read_xml_dom; do
        if [ "$ENTITY" = 'value' ]; then
            value="$CONTENT"
        fi
        if [ "$ENTITY" = 'code' ]; then
            code=$CONTENT
        fi
        if [ "$ENTITY" = 'message' ]; then
            message="$CONTENT"
        fi
    done < ${TMPDIR}/create_ddns.xml

    if [ "$code" = '1' ]; then
        echo "$value";
        return 0;
    else
        echo "$message";
        return $code;
    fi
}

init()
{
    mkdir -p ${TMPDIR}
}

clean()
{
:
#    rm -rf ${TMPDIR}
}

exiterr() {
  echo "ERROR: ${1}" >&2
  clean
  exit 1
}





echo -n '初始化...'
export TMPDIR='/tmp/ddns-dnspod'
export OLDIPFILE="/tmp/ddns-dnspod-oldip"
export OLDIPFILEV6="/tmp/ddns-dnspod-oldip-v6"
init
echo '[done]'

echo -n '读取配置文件...'
. "$(dirname $0)/config.sh"
echo '[done]'

v4() {
    echo -n '获取本地公网IP...'
    ip=$(get_localip) ||
    {
        echo '[error]'
        exiterr "获取本地公网IP失败"
    } &&
    {
        echo "[$ip]"
    }

    echo -n '比较上次IP...'
    oldip=$(cat "$OLDIPFILE" 2>/dev/null)
    if [ "$oldip" = "$ip" ]; then
        echo '[nochange]'
        return 0
    else
        echo "[change]"
    fi

    echo -n '获取domain_id...'
    return=$(get_domain_id "$login_token" "$domain") || 
    {
        echo '[error]'
        exiterr "$return"
    }
    domain_id=$return
    echo "[$domain_id]"

    echo -n '获取record_id...'
    return=$(get_record_id "$login_token" "$domain_id" "$record" "A") || 
    {
        echo '[error]'
        exiterr "$return"
    }
    record_id=$return
    if [ "$record_id" = '' ]; then
        echo '[null]'

        echo -n '没有找到对应record_id，创建新record...'
        return=$(create_record "$login_token" "$domain_id" "$record" "A" "$ip") || 
        {
            echo '[error]'
            exiterr "$return"
        }
        record_id=$return
        echo "[$record_id]"
    else
        echo "[$record_id]"

        echo -n '更新DDNS...'
        return=$(ddns_record "$login_token" "$domain_id" "$record_id" "$record") || 
        {
            echo '[error]'
            exiterr "$return"
        }
        value=$return
        echo "[$value]"
    fi

    echo "$ip" 2>/dev/null > $OLDIPFILE
}

v6() {
    echo -n '获取本地公网IPv6...'
    ipv6=$(get_localip_v6) ||
    {
        echo '[error]'
        exiterr "获取本地公网IPv6失败"
    } &&
    {
        echo "[$ipv6]"
    }

    echo -n '比较上次IPv6...'
    oldipv6=$(cat "$OLDIPFILEV6" 2>/dev/null)
    if [ "$oldipv6" = "$ipv6" ]; then
        echo '[nochange]'
        return 0
    else
        echo "[change]"
    fi

    echo -n '获取domain_id...'
    return=$(get_domain_id "$login_token" "$domain") || 
    {
        echo '[error]'
        exiterr "$return"
    }
    domain_id=$return
    echo "[$domain_id]"

    echo -n '获取record_id...'
    return=$(get_record_id "$login_token" "$domain_id" "$record_v6" "AAAA") || 
    {
        echo '[error]'
        exiterr "$return"
    }
    record_id=$return
    if [ "$record_id" = '' ]; then
        echo '[null]'

        echo -n '没有找到对应record_id，创建新record...'
        return=$(create_record "$login_token" "$domain_id" "$record_v6" "AAAA" "$ipv6") || 
        {
            echo '[error]'
            exiterr "$return"
        }
        record_id=$return
        echo "[$record_id]"
    else
        echo "[$record_id]"

        echo -n '更新DDNS...'
        return=$(ddns_record_v6 "$login_token" "$domain_id" "$record_id" "$record_v6" "$ipv6") || 
        {
            echo '[error]'
            exiterr "$return"
        }
        value=$return
        echo "[$value]"
    fi

    echo "$ipv6" 2>/dev/null > $OLDIPFILEV6
}

if [ "$record" = "" ]; then
    echo '跳过IPv4'
else
    v4
fi
if [ "$record_v6" = "" ]; then
    echo '跳过IPv6'
else
    v6
fi

clean
exit 0
