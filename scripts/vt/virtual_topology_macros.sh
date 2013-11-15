#!/bin/bash
#
# This file contains some configuration file macros useful to create large
# topologies.
#
# #############################################################################

# #############################################################################
# Creates a virtual topology with a given number of vms and vnets with a
# well defined naming scheme.
#
# Virtual machines are named:
#    ${branch}${cfgi}_vm${router number}
# Virtual networks are named:
#   ${branch}${cfgi}_n${network number}
# MAC Addresses are assigned:
#   00:00:88:<cfgi>:<network number>:0<router number>
# IP Addresses are assigned:
#   192.168.<cfgi><network number>.1<router number>
# IPv6 Addresses are assigned:
#   20<cfgi><network number>::1<router number>
#
# All inputs are optional. This assumes the isodir has an iso named:
#   ${branch}_${isotag}.iso
# The virtual machines are connected to the virtual networks in a mesh.
#
# Input:
#   cfgi: A configuration index used to make the topology names unique.
#   num_vms: The number of virtual machines to make.
#   num_vnets: The number of virtual networks to make.
#   branch: A branch name for unique naming of the topology.
#   isotag: A tag appended to the iso name.
#   isodir: The iso directory.
# #############################################################################
function virtual_topology_configure {
  local cfgi=${1:-0}
  local num_vms=${2:-1}
  local num_vnets=${3:-2}
  local branch=${4:-master}
  local isotag=${5:-`date +%m_%d_%y`}
  local isodir=${6:-"$menv_local_dir/iso"}

  echo "Creating a virtual topology with ${num_vms} vms and ${num_vnets}"\
    "vnets connected as a mesh."

  let num_vms-=1
  let num_vnets-=1

  # Create VMs
  for vmsi in $(eval echo {0..${num_vms}}) ; do
    vm=${branch}${cfgi}_vm${vmsi}
    vmt=${vm_types[$vmsi]}

    vt_vm $vm
    vt_vm_type $vm $vmt

    if [ -f "${isodir}/${branch}_${isotag}_${vmt}.iso" ] ; then
      vt_vm_iso $vm "${isodir}/${branch}_${isotag}_${vmt}.iso"
    elif [ -f "${isodir}/${branch}_${isotag}_${vmt}.qcow2" ] ; then
      vt_vm_iso $vm "${isodir}/${branch}_${isotag}_${vmt}.qcow2"
    fi

    # Create VINTs
    for vneti in $(eval echo {0..${num_vnets}}) ; do
      vt_vint $vm ${branch}${cfgi}_n${vneti} \
        00:00:88:0${cfgi}:0${vneti}:0${vmsi} 1${vmsi} 0:1${vmsi}
    done
  done

  # Create VNETs
  for vneti in $(eval echo {0..${num_vnets}}) ; do
    vt_vnet ${branch}${cfgi}_n${vneti} "192.168.${cfgi}${vneti}" \
                                         "20${cfgi}${vneti}:0"
  done
}

# #############################################################################
# Initilizes an array of port names for use by other functions..
# #############################################################################
function virtual_topology_intnames {
  local intnames=$1
  local vm_type=$2

  for pf in $intnames ; do
    eval "int_names_$vm_type+=($pf)"
  done
}

# #############################################################################
# Sets the vm types for the configuration.
# #############################################################################
function vt_vm_types {
  local types=""

  for type in ${@:1} ; do 
    types+="'$type' "
  done

  eval "vm_types=($types)"
}

# #############################################################################
# Intilizes an array of virtual device interfaces for a given device.
# #############################################################################
function vt_vm_int_statuses {
  local branch=$1
  local cfgi=$2
  local vmsi=$3
  local statuses=""

  for int_status in ${@:4} ; do 
    statuses+="'$int_status' "
  done

  eval "${branch}${cfgi}_vm${vmsi}=($statuses)"
}

# #############################################################################
# Adds a command to the command list for vms matching the vm type (or all if not
# specified)
# #############################################################################
function vt_cmd {
  local cmd=$1
  local typ=$2
  
  for vmsi in $(eval echo {0..$((num_vms-1))}) ; do
    vtyp=${vm_types[$vmsi]}
    if [[ -z $typ || "$typ" == "$vtyp" ]] ; then
      vt_cmds[$vmsi]+="$cmd"$'\n'
    fi
  done
}

# #############################################################################
# Adds a command to the command list for the specified vm.
# #############################################################################
function vt_vm_cmd {
  local vm=$1
  local cmd=$2

  vt_cmds[$vm]+="$cmd"$'\n'
}

# #############################################################################
# Adds a command to the command list for the specified vm if it matches the vm
# type subsitutituing a interface name
# #############################################################################
function vt_int_cmd {
  local interface=$1
  local cmd=$2
  local typ=$3
  
  for vmsi in $(eval echo {0..$((num_vms-1))}) ; do
    local vtyp=${vm_types[$vmsi]}
    if [[ -z $typ || "$typ" == "$vtyp" ]] ; then
      local intnamearr=int_names_$vtyp
      local intname=`eval echo \$\{$intnamearr\[$interface\]\}`
      vt_int_cmds[$vmsi]+="${cmd/INTERFACE/$intname}"$'\n'
    fi
  done
}

# #############################################################################
# Adds a command for ever interface on every device matching the vm type and
# doing interface subsitutions.
# #############################################################################
function vt_int_all_cmd {
  local cmd="$1"
  local typ=$2

  local intnamearr=int_names_$typ
  local intnum=`eval echo \$\{\#$intnamearr\[@\]\}`
  for ((i=0;i<${intnum};++i)); do
    vt_int_cmd $i "$cmd" "$typ"
  done
}

# #############################################################################
# Sets up all the virtual topology commands.
# #############################################################################
function virtual_topology_commands {
  local cfgi=$1
  local branch=$2

  for vmsi in $(eval echo {0..$((num_vms-1))}) ; do
    local vm=${branch}${cfgi}_vm${vmsi}
    local cmds="$(vt_vm_type_execute $vm vm_commands $vmsi)"

    vt_vm_commands $vm "$cmds"
  done
}

