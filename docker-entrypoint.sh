#!/bin/bash

set -e
#set -x

OVN_DRIVER_CMD="/usr/bin/docker-ovn-driver"
OVN_DRIVER_SOCK="/run/docker/plugins/ovn.sock"
SOCAT_LOG="/var/log/openvswitch/docker-ovn-socat.log"

printf "Environment variables:\n"
env

if [ "${OVN_DRIVER_PORT:-}" == "" ]; then
    OVN_DRIVER_PORT="9105"
    printf "OVN_DRIVER_PORT is empty, setting default: ${OVN_DRIVER_PORT}\n";
fi

if [ "${OVN_DRIVER_ADDR:-}" == "" ]; then
    OVN_DRIVER_ADDR="127.0.0.1"
    printf "OVN_DRIVER_ADDR is empty, setting default: ${OVN_DRIVER_ADDR}\n";
fi

if [ -z ${DEBUG+x} ]; then
    printf "Debugging is OFF\n"
else
    if test ${DEBUG} -gt 0; then
        printf "Debugging is ON\n";
        OVN_DOCKER_OPTS+=" --verbose=dbg";
    else
        printf "Debugging is OFF\n";
    fi
fi

if [ "$#" -lt 1 ]; then
    printf "No arguments passed.\n";
fi

if [ "${OVN_DOCKER_OPTS:-}" == "" ]; then
    printf "OVN_DOCKER_OPTS is empty, setting default values.\n";
    OVN_DOCKER_OPTS="--log-file /var/log/openvswitch/docker-ovn-driver.log";
    OVN_DOCKER_OPTS+=" --distributed";
    OVN_DOCKER_OPTS+=" --health-check-on";
    OVN_DOCKER_OPTS+=" --health-check-interval 360";
    OVN_DOCKER_OPTS+=" --ip-lookup";
    OVN_DOCKER_OPTS+=" --docker-driver-scope local";
    OVN_DOCKER_OPTS+=" --bind-ip ${OVN_DRIVER_ADDR}";
    OVN_DOCKER_OPTS+=" --bind-port ${OVN_DRIVER_PORT}";
    OVN_DOCKER_OPTS+=" --verbose console:off";
    OVN_DOCKER_OPTS+=" --verbose syslog:off";
fi

function run_socat(){
    touch ${SOCAT_LOG}
    nohup socat -s -D -lu -lh -lf ${SOCAT_LOG} -d -d -d -d UNIX-LISTEN:${OVN_DRIVER_SOCK},fork TCP:${OVN_DRIVER_ADDR}:${OVN_DRIVER_PORT} >> ${SOCAT_LOG} 2>&1 &
    nohup "curl --connect-timeout 15 --unix-socket ${OVN_DRIVER_SOCK} -X GET http:/NetworkDriver.Database; cat ${SOCAT_LOG}" >> ${SOCAT_LOG} 2>&1 &
}

function run_driver(){
    COMMAND="${OVN_DRIVER_CMD} ${OVN_DOCKER_OPTS}";
    printf "About to start Docker Overlay Driver for OVN ...\n";
    printf "Host files:\n";
    find /var/{run,lib,log}/openvswitch /etc/openvswitch /etc/ssl/ovn /usr/share/openvswitch -type f -printf 'file:%h/%f\n'
    printf "Entrypoint: $COMMAND\n";
    exec ${COMMAND}
}

for i in "$@"; do
    case $i in
        -h|--help)
        $OVN_DRIVER_CMD --help;
        ;;
        *)
        if [[ ${i} == *"entrypoint"* ]]; then
            printf "Reached entrypoint ...\n";
        else
            OVN_DOCKER_OPTS+=" ${i#*=}"
        fi
        ;;
    esac
done

run_socat
run_driver $OVN_DOCKER_OPTS
