#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR && cd ..
MANAGER_IP=127.0.0.1
DEFAULT_ROUTE_INTERFACE=$(cat /proc/net/route | cut -f1,2 | grep 00000000 | cut -f1)
LOCAL_IP=$(ip addr show dev $DEFAULT_ROUTE_INTERFACE | grep "inet " | sed "s/.*inet //" | cut -d"/" -f1)
ENCAP_TYPE=geneve
ovs-vsctl set Open_vSwitch . \
    external_ids:ovn-remote="tcp:$MANAGER_IP:6642" \
    external_ids:ovn-nb="tcp:$MANAGER_IP:6641" \
    external_ids:ovn-encap-ip=$LOCAL_IP \
    external_ids:ovn-encap-type="$ENCAP_TYPE"

echo "Manager: ${MANAGER_IP}, Local IP: ${LOCAL_IP}, Encapsulation: ${ENCAP_TYPE}"
