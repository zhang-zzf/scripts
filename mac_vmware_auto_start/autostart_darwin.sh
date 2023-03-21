#!/usr/bin/env bash

workdir="/Applications/VMware Fusion.app/Contents"
echo "vmware [$(date)] [$(whoami)] workdir-> ${workdir}"
vmware_dir="/Users/admin/Workspace/NoBackups/vmware"
autostart_file="${vmware_dir}/autostart.vms"

function shutdown()
{
  echo "vmware [$(date)] [$(whoami)] Received a signal to shutdown"

  if [ -f  "${autostart_file}" ]; then
      while read -r vmx; do
        echo "vmware [$(date)] [$(whoami)] stop vm-> ${vmx}"
        "${workdir}"/Library/vmrun -T fusion stop "${vmx}"
      done < "${autostart_file}"
  fi

  exit 0
}

function startup()
{
  echo "vmware [$(date)] [$(whoami)] Starting..."
  if [ -f  "${autostart_file}" ]; then
      while read -r vmx; do
        echo "vmware [$(date)] [$(whoami)] start vm-> ${vmx}"
        if [[ "${vmx}" == *"ds918_7.0.1_42218.vmx"* ]]; then
            echo "vmware need to start ds918_7.0.1_42218.vmx"
            ds918_dir="$(dirname "${vmx}")"
            "${ds918_dir}/ST4000LM024-2AN17V_disk_init.sh" ST4000LM024-2AN17V "${ds918_dir}"
        fi
        "${workdir}"/Library/vmrun -T fusion start "${vmx}" nogui
      done < "${autostart_file}"
      echo "vmware [$(date)] [$(whoami)] Started."
      tail -f /dev/null &
      wait $!
  fi
}

trap shutdown SIGTERM
# trap shutdown SIGKILL

startup;