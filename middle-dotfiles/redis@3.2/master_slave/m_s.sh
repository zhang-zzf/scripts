#! /bin/bash

SHELL_FOLDER=$(cd "$(dirname "$0")";pwd)

REDIS_SERVER=/usr/local/opt/redis@3.2/bin/redis-server

TMP_DIR="/tmp/"

ports=(6470 6471 6472 6473)

_start() {
    host=${1}
    for port in ${ports[@]}; do
        dir="${TMP_DIR}/${port}/"
        if [ ! -d "${dir}" ]; then
            mkdir -p "${dir}"; cp ${SHELL_FOLDER}/redis.conf ${dir}
        fi

        if [ "${port}" = "${ports[0]}" ]; then
            cd ${dir} && ${REDIS_SERVER} ${dir}/redis.conf \
                --dir "${dir}" \
                --bind "0.0.0.0" \
                --port "${port}" \
                --pidfile "${dir}/redis.pid"
        else
            cd ${dir} && ${REDIS_SERVER} ${dir}/redis.conf \
                --dir "${dir}" \
                --bind "0.0.0.0" \
                --port "${port}" \
                --slaveof ${host} ${ports[0]} \
                --pidfile "${dir}/redis.pid"
        fi
    done
}

_stop() {
    for port in ${ports[@]}; do
        kill `cat ${TMP_DIR}/${port}/redis.pid`
    done
}

case "$1" in
start)
    shift
    host=${1}
    host=${host:=127.0.0.1}
    _start ${host}
    echo "redis database started"
;;
stop)
    _stop
    echo "redis database stopped"
;;
restart)
    _stop && _start
;;
*)
    echo "Usage: ${0} start/stop/restart"
;;
esac
