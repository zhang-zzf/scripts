#!/usr/bin/env bash
workdir=$(cd "$(dirname "$0")" || exit; pwd)

echo "workdir -> ${workdir}"
cd "${workdir}" || exit
source ../venv/bin/activate

export PROJ_ENV=prod
export TIME_ZONE=Asia/Shanghai
export TZ=Asia/Shanghai

nohup python main.py U_VIDEOS_CNT=2048 &>/dev/null &
