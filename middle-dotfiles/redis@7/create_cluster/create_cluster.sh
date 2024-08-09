#!/bin/bash
# auth zzf.zhang

workdir=$(cd "$(dirname "$0")" || exit && pwd)
rm -f redis_nodes.txt

# targetAddress redisStartPort instanceNum
# admin@10.255.1.1:22 7000 16
_create_node() {
  cd "${workdir}" || exit
  local address=${1}
  local redisPort=${2}
  local num=${3}
  # username@ip:port
  # 注意 有个空格
  local arr=("${address//@/ }")
  if [ ${#arr[*]} == 1 ]; then
    # 10.255.1.1:22
    local username="admin"
    arr=("${arr[0]//:/ }")
  else
    # admin@10.255.1.1:22
    local username=${arr[0]}
    arr=("${arr[1]//:/ }")
  fi
  local nodeIp=${arr[0]}
  # default 22
  local nodePort=${arr[1]:-22}
  # scp bin to remote node
  cd ${workdir}
  scp -P ${nodePort} -r redis_7.0.5_64 ${username}@${nodeIp}: &>/dev/null
  ssh -p ${nodePort} ${username}@${nodeIp} "pkill -9 redis-server && sleep 5s; \
      cd ~; \
      rm -r redis_cluster; mkdir -p redis_cluster; \
      mv redis_7.0.5_64 redis_cluster/bin; \
      "
  # 创建目录
  rm -r ${nodeIp}
  mkdir ${nodeIp}
  cd ${nodeIp}
  # for
  ((num = ${num} - 1))
  for i in $(seq 0 ${num}); do
    # 数字加法
    ((port = ${redisPort} + ${i}))
    echo "redis instance-> ${address}, ${port}"
    mkdir ${port}
    cp ${workdir}/redis.conf ${port}
    sed -i "1s/6379/${port}/" ${port}/redis.conf
    scp -r ${port} ${username}@${nodeIp}:~/redis_cluster/ &>/dev/null
    ssh ${username}@${nodeIp} "cd ~/redis_cluster/${port}; \
          ~/redis_cluster/bin/redis-server redis.conf \
          "
    instances="${instances} ${nodeIp}:${port}"
    echo "- redis://${nodeIp}:${port}" >>${workdir}/redis_nodes.txt
  done
}

_interactive() {
  echo "" >${workdir}/redis_nodes.txt
  instances=""
  while :; do
    cd ${workdir}
    echo "dirname: ${workdir}"
    read -p "Enter the NodeAddress[username@ip:port]: " nodeAddress
    if [ "${nodeAddress}" == "" ]; then
      break
    fi
    read -p "Enter the instance num[default 4]: " num
    num=${num:-4}
    read -p "Enter the start port[default 7000]: " redisPort
    redisPort=${redisPort:-7000}
    _create_node ${nodeAddress} ${redisPort} ${num}
  done
  echo "Redis instances: ${instances}"
  read -p "Now create redis_cluster, replicas[default 1]: " replicas
  replicas=${replicas:-1}
  ${workdir}/redis_7.0.5_64/redis-cli --cluster create ${instances} --cluster-replicas ${replicas}
}

# batch admin@10.255.1.41:22,admin@10.255.1.42,10.255.1.43 7000 16 1
_batch() {
  cd ${workdir}
  echo "dirname: ${workdir}"
  echo "" >${workdir}/redis_nodes.txt
  # 注意空格
  addresses=(${1//,/ })
  redisStartPort=${2}
  redisInstancePerNode=${3}
  replicas=${4:-0}
  instances=""
  for nodeAddress in ${addresses[@]}; do
    _create_node ${nodeAddress} ${redisStartPort} ${redisInstancePerNode}
  done
  echo "Redis instances: ${instances}"
  ${workdir}/redis_7.0.5_64/redis-cli --cluster create ${instances} --cluster-replicas ${replicas}
}

case "$1" in
batch)
  shift
  _batch $@
  ;;
*)
  echo "Usage: ${0} batch admin@10.255.1.41:22,admin@10.255.1.42 7000 16 1"
  _interactive
  ;;
esac
