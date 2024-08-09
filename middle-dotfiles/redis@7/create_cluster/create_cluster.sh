#!/bin/bash
# auth zzf.zhang

workdir=$(cd "$(dirname "$0")" || exit && pwd)
rm -f redis_nodes.txt

# targetAddress redisStartPort instanceNum
# admin@10.255.1.1:22 7000 16
_create_node() {
  cd "${workdir}" || exit
  local node_addr=${1}
  local -i redis_start_port=${2}
  local instance_num=${3}
  # username@ip:port
  # 注意 有个空格
  # shellcheck disable=SC2206
  local arr=(${node_addr//@/ })
  if [ ${#arr[*]} == 1 ]; then
    # 10.255.1.1:22
    local username="admin"
    # shellcheck disable=SC2206
    arr=(${arr[0]//:/ })
  else
    # admin@10.255.1.1:22
    local username=${arr[0]}
    # shellcheck disable=SC2206
    arr=(${arr[1]//:/ })
  fi
  local node_ip=${arr[0]}
  # default 22
  local -i node_ssh_port=${arr[1]:-22}
  # scp bin to remote node
  cd "${workdir}" || exit
  scp -P ${node_ssh_port} -r redis_7.0.5_64 "${username}@${node_ip}": &>/dev/null
  ssh -p ${node_ssh_port} "${username}@${node_ip}" "pkill -9 redis-server && sleep 5s; \
      cd ~; \
      rm -r redis_cluster; mkdir -p redis_cluster; \
      mv redis_7.0.5_64 redis_cluster/bin; \
      "
  # 创建目录
  rm -r "${node_ip}" && mkdir "${node_ip}"; cd "${node_ip}" || exit
  for((i=0;i<instance_num;i++)); do
    # 数字加法
    declare -i redis_port
    ((redis_port = redis_start_port + i))
    echo "redis instance-> ${node_addr}, ${redis_port}"
    mkdir ${redis_port}
    cp "${workdir}"/redis.conf ${redis_port}
    sed -i "1s/6379/${redis_port}/" ${redis_port}/redis.conf
    scp -r ${redis_port} "${username}@${node_ip}":~/redis_cluster/ &>/dev/null
    # shellcheck disable=SC2029
    ssh "${username}@${node_ip}" "cd ~/redis_cluster/; \
          bin/redis-server ${redis_port}/redis.conf \
          "
    instances="${instances} ${node_ip}:${redis_port}"
    echo "- redis://${node_ip}:${redis_port}" >>"${workdir}"/redis_nodes.txt
  done
}

_interactive() {
  echo "" >"${workdir}"/redis_nodes.txt
  instances=""
  while :; do
    cd "${workdir}" || exit
    echo "dirname: ${workdir}"
    read -r -p "Enter the NodeAddress[username@ip:port]: " node_addr
    if [ "${node_addr}" == "" ]; then
      break
    fi
    read -r -p "Enter the instance num[default 4]: " instance_num
    instance_num=${instance_num:-4}
    read -r -p "Enter the start port[default 7000]: " redis_start_port
    redis_start_port=${redis_start_port:-7000}
    _create_node "${node_addr}" "${redis_start_port}" "${instance_num}"
  done
  echo "Redis instances: ${instances}"
  read -r -p "Now create redis_cluster, replicas[default 1]: " replicas
  replicas=${replicas:-1}
  "${workdir}"/redis_7.0.5_64/redis-cli --cluster create "${instances}" --cluster-replicas "${replicas}"
}

# batch admin@10.255.1.41:22,admin@10.255.1.42,10.255.1.43 7000 16 1
_batch() {
  cd "${workdir}" || exit
  echo "dirname: ${workdir}"
  echo "" >"${workdir}"/redis_nodes.txt
  # 注意空格
  # shellcheck disable=SC2206
  addresses=(${1//,/ })
  redis_start_port=${2}
  instance_num=${3}
  replicas=${4:-0}
  instances=""
  for node_addr in "${addresses[@]}"; do
    _create_node "${node_addr}" "${redis_start_port}" "${instance_num}"
  done
  echo "Redis instances: ${instances}"
  "${workdir}"/redis_7.0.5_64/redis-cli --cluster create "${instances}" --cluster-replicas "${replicas}"
}

case "$1" in
batch)
  shift
  _batch "$@"
  ;;
*)
  echo "Usage: ${0} batch admin@10.255.1.41:22,admin@10.255.1.42 7000 16 1"
  _interactive
  ;;
esac
