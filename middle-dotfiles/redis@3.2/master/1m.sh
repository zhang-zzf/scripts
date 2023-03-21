#! /bin/bash

SHELL_FOLDER=$(cd "$(dirname "$0")";pwd)

REDIS_SERVER=/usr/local/opt/redis@3.2/bin/redis-server

TMP_DIR="/tmp/"

ports=(6379)

_start() {
    for port in ${ports[@]}; do
        dir="${TMP_DIR}/${port}/"
        if [ ! -d "${dir}" ]; then
            mkdir -p "${dir}"; cp ${SHELL_FOLDER}/redis.conf ${dir}
        fi
        cd ${dir} && ${REDIS_SERVER} ${dir}/redis.conf \
            --dir "${dir}" \
            --port "${port}" \
            --pidfile "${dir}/redis.pid"
        echo "redis database @${port} started"
    done
}

_stop() {
    for port in ${ports[@]}; do
        kill `cat ${TMP_DIR}/${port}/redis.pid`
        echo "redis database @${port} stopped"
    done
}

case "$1" in
start)
    shift;
    ports=($@)
    _start
;;
stop)
    shift;
    ports=($@)
    _stop
;;
restart)
    shift;
    ports=($@)
    _stop && _start
;;
*)
    echo "Usage: ${0} start/stop/restart"
;;
esac
