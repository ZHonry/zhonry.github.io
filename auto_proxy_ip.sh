#!/bin/sh


function installNetTools() {
    yum install net-tools tar make -y
}

function installFirewall() {
    yum install firewalld -y
    systemctl start firewalld
    systemctl enable firewalld
    
    echo '<?xml version="1.0" encoding="utf-8"?>'         > /usr/lib/firewalld/services/tinyproxy.xml
    echo '<service>'                                      >> /usr/lib/firewalld/services/tinyproxy.xml
    echo '    <short>tinyproxy</short>'                   >> /usr/lib/firewalld/services/tinyproxy.xml
    echo '    <description>tinyproxy</description>'       >> /usr/lib/firewalld/services/tinyproxy.xml
    echo '    <port protocol="tcp" port="51333"/>'        >> /usr/lib/firewalld/services/tinyproxy.xml
    echo '</service>'                                     >> /usr/lib/firewalld/services/tinyproxy.xml
    
    firewall-cmd --zone=public --add-service=tinyproxy --permanent
    firewall-cmd --reload
    firewall-cmd --list-services
}

function installTinyproxy() {
    yum install gcc -y
    yum install wget -y
    rm -rf tinyproxy-1.11.1.tar.gz
    rm -rf tinyproxy-1.11.1
    wget https://github.com/tinyproxy/tinyproxy/releases/download/1.11.1/tinyproxy-1.11.1.tar.gz /root
    tar -zxvf tinyproxy-1.11.1.tar.gz
    cd tinyproxy-1.11.1
    
    # yum install git -y
    # rm -rf /root/tinyproxy
    # git clone https://github.com/tinyproxy/tinyproxy.git /root/tinyproxy
    # cd /root/tinyproxy
    
    rm -rf /opt/tinyproxy
    ./configure --prefix=/opt/tinyproxy/
    make
    make install
}

function initConfig() {
    ifconfig | grep -A1 eth0 | grep inet | awk -F' ' '{print $2}' > /root/ip.txt
    fip=`head -1 /root/ip.txt`
    index=1
    cat /root/ip.txt |while read ip
    do
        echo 'Port 51333'                        >  /root/tc$index.conf
        echo "Listen $ip"                        >> /root/tc$index.conf
        echo "BIND $ip"                          >> /root/tc$index.conf
        echo 'Timeout 600'                       >> /root/tc$index.conf
        echo '# Allow ANY'                       >> /root/tc$index.conf
        echo 'BasicAuth hangyin RvHfzHXA7z96hC'  >> /root/tc$index.conf
        /opt/tinyproxy/bin/tinyproxy -c /root/tc$index.conf
        echo "INSERT INTO t_proxy(host, port, username, password, enable, remark) VALUES('$ip', 51333, 'hangyin', 'RvHfzHXA7z96hC', 1, '$fip') "
        index=`expr $index + 1`
    done
}

installNetTools
echo "install net-tools done."

installFirewall
echo "install firewall done."

installTinyproxy
echo "install tinyproxy done."

initConfig
echo "initConfig done."

netstat -anop | grep 51333
