#!/bin/bash

DIR="$( cd "$( dirname "$0" )" && pwd )"

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

DIR=${SCRIPTPATH}
ROOTFS=$DIR/rootfs

ROUTER_DEV="venet0"

#tap接口不能重复
TAP_DEV="tap0"
#tap接口ip
export HOST_TAP_IP="10.0.0.1"
#接口转发端口
export HOST_PORT=40401

UML_ID="ss${HOST_PORT}"

# same LAN with HOST_TAP_IP
export UML_IP="10.0.0.2"
export UML_SS_PORT=40401
export UML_SS_METHOD="chacha20"
export UML_SS_PASSWD="ss123456"
export UML_MEM="16M"

#root password: root1234
#ssh -p 30022 ${UML_IP}

START_UML=${DIR}/start_uml.sh


#TEST UML_IP is dup?



echo "#!/bin/sh" > ${START_UML}

#Check
[ ! -d /sys/class/net/$TAP_DEV ] && echo "ip tuntap add ${TAP_DEV} mode tap" | tee -a ${START_UML}
#[ ! -d /sys/class/net/$TAP_DEV ] && ip tuntap add ${TAP_DEV} mode tap

TEST_TAP_IP=`ifconfig ${TAP_DEV} | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
#echo "TEST_TAP_IP" ${TEST_TAP_IP}

[[  -z  $TEST_TAP_IP  ]] && echo "ip addr add ${HOST_TAP_IP}/24 dev $TAP_DEV" | tee -a ${START_UML}
#[[  -z  $TEST_TAP_IP  ]] && ip addr add ${HOST_TAP_IP}/24 dev $TAP_DEV

[[  -z  $TEST_TAP_IP  ]] && echo "ip link set ${TAP_DEV} up" | tee -a ${START_UML}
#[[  -z  $TEST_TAP_IP  ]] && ip link set ${TAP_DEV} up

#Check
echo "iptables -P FORWARD ACCEPT" | tee -a ${START_UML}
echo "echo 1 > /proc/sys/net/ipv4/ip_forward" |  tee -a ${START_UML}

#Check
TEST_MASQUERADE=`iptables -t nat -L -n -v |grep MASQUERADE| grep ${ROUTER_DEV}`

#echo "TEST_MASQUERADE [$TEST_MASQUERADE]"

[[ -z  $TEST_MASQUERADE ]] && echo "iptables -t nat -A POSTROUTING -o ${ROUTER_DEV} -j MASQUERADE" |  tee -a ${START_UML}
#[[ -z  $TEST_MASQUERADE ]] && iptables -t nat -A POSTROUTING -o ${ROUTER_DEV} -j MASQUERADE

#ssh控制端口转发
# #iptables -t nat -A PREROUTING -i ${ROUTER_DEV} -p tcp --dport 30022 -j DNAT --to-destination ${UML_IP}:30022

#Check
TEST_TCP_PORT=`iptables -L -t nat |grep tcp|grep ${UML_IP}`
[[ -z  $TEST_TCP_PORT ]] && echo "iptables -t nat -A PREROUTING -i ${ROUTER_DEV} -p tcp --dport ${HOST_PORT} -j DNAT --to-destination ${UML_IP}:${UML_SS_PORT}" |  tee -a ${START_UML}
#[[ -z  $TEST_TCP_PORT ]] && iptables -t nat -A PREROUTING -i ${ROUTER_DEV} -p tcp --dport ${HOST_PORT} -j DNAT --to-destination ${UML_IP}:${UML_SS_PORT}
#echo "TEST_TCP_PORT" $TEST_TCP_PORT

TEST_UDP_PORT=`iptables -L -t nat |grep udp|grep ${UML_IP}`
[[ -z  $TEST_UDP_PORT ]] && echo "iptables -t nat -A PREROUTING -i ${ROUTER_DEV} -p udp --dport ${HOST_PORT} -j DNAT --to-destination ${UML_IP}:${UML_SS_PORT}" |  tee -a ${START_UML}
#[[ -z  $TEST_UDP_PORT ]] && iptables -t nat -A PREROUTING -i ${ROUTER_DEV} -p udp --dport ${HOST_PORT} -j DNAT --to-destination ${UML_IP}:${UML_SS_PORT}

#echo "TEST_UDP_PORT" $TEST_UDP_PORT

#config ${DIR}/etc/network/interfaces
envsubst < interfaces.tlp > ${ROOTFS}/etc/network/interfaces


#config ${DIR}/etc/shadowsocks-libev/config.json
envsubst < config.tlp.json > ${ROOTFS}/etc/shadowsocks-libev/config.json

#初始化swap, 默认16M 
dd if=/dev/zero of=${DIR}/uml-swap bs=1024K count=16

echo "${DIR}/vmlinux umid=${UML_ID} root=/dev/root rootfstype=hostfs rootflags=${ROOTFS} rw ubd0=${DIR}/uml-swap mem=${UML_MEM} eth0=tuntap,${TAP_DEV} " |  tee -a ${START_UML}
#echo "./vmlinux umid=${UML_ID} root=/dev/root rootfstype=hostfs rootflags=${ROOTFS} rw ubd0=${DIR}/uml-swap mem=${UML_MEM} eth0=tuntap,${TAP_DEV} " >> ${DIR}/start_uml.sh
chmod a+x ${DIR}/start_uml.sh
