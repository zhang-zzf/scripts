#! /bin/bash

SHELL_FOLDER=$(cd "$(dirname "$0")";pwd)

REDIS_SERVER=/usr/local/opt/redis@3.2/bin/redis-server

TMP_DIR="/tmp"

PORT_PRE=7700

declare -a ports
for ((i=0;i<12;i++));do
    ports[${i}]=$[${PORT_PRE}+${i}]
done

_start() {
    for port in ${ports[@]}; do
        dir="${TMP_DIR}/${port}/"
        if [ ! -d "${dir}" ]; then
            mkdir -p "${dir}" 2>/dev/null
            cp ${SHELL_FOLDER}/redis.conf ${dir}
        fi
        cd ${dir} && ${REDIS_SERVER} ${dir}/redis.conf\
            --dir "${dir}" \
            --bind "0.0.0.0"\
            --port "${port}"\
            --pidfile "${dir}/redis.pid"\
            --daemonize yes
    done
}

_stop() {
    for port in ${ports[@]}; do
        dir="${TMP_DIR}/${port}" && kill `cat ${dir}/redis.pid`
    done
}

_cluster() {
    host=${1}
    host=${host:=127.0.0.1}
    hosts=""
    for port in ${ports[@]}; do
        hosts="${hosts} ${host}:${port}"
    done
    ./redis-trib.rb create --replicas 3 ${hosts}
}

case "$1" in
start)
    shift;_start
    echo "redis database started"
;;
stop)
    _stop
    echo "redis database stopped"
;;
restart)
    _stop && _start
;;
cluster)
    _cluster $2
;;
*)
    echo "Usage: ${0} start/stop/restart"
;;
esac
