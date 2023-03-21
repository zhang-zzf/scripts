#!/bin/bash

workdir=$(cd $(dirname $0); pwd)

while :;do
    cd ${workdir}
    echo "dirname: ${workdir}"
    read -p "Enter the port: " port
    if [ "${port}" == "" ]; then
        break
    fi
    mkdir -p ${port}
    cp ./redis.conf ${port}/
    sed -i "1s/6379/${port}/" ${port}/redis.conf
    cd ${port} && redis-server ./redis.conf
done
