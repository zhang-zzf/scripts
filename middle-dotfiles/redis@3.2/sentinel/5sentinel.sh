#! /bin/bash

SHELL_FOLDER=$(cd "$(dirname "$0")";pwd)

REDIS_SERVER=/usr/local/opt/redis@3.2/bin/redis-server

TMP_DIR="/tmp"

PORT_PRE="2770"

declare -a ports
for ((i=0;i<5;i++));do
    ports[${i}]="${PORT_PRE}${i}"
done

_start() {
    for port in ${ports[@]}; do
        dir="${TMP_DIR}/${port}/"
        mkdir -p "${dir}" 2>/dev/null
        # then sentinel server will rewrite the config, so must copy it to dir
        if [ ! -f "${dir}/sentinel.conf" ]; then
            cp "${SHELL_FOLDER}/sentinel.conf" "${dir}"
        fi
        cd ${dir} && ${REDIS_SERVER} ${dir}/sentinel.conf --sentinel \
            --dir "${dir}" \
            --bind "0.0.0.0" \
            --port "${port}" \
            --pidfile "${dir}/redis.pid" \
            --daemonize yes
    done
}

_stop() {
    for port in ${ports[@]}; do
        dir="${TMP_DIR}/${port}" && kill `cat ${dir}/redis.pid`
    done
}

case "$1" in
start)
    echo "starting redis sentinel..."
    shift;_start
    echo "redis sentinel started"
;;
stop)
    echo "stopping redis sentinel..."
    _stop
    echo "redis sentinel stopped"
;;
restart)
    _stop && _start
;;
*)
    echo "Usage: ${0} start/stop/restart"
;;
esac
