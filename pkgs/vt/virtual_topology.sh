#!/bin/bash
#
# This file contains functionality to create and store a virtual topology.
#
# #############################################################################

# Include the virsh wrappers.
. ${vt_install_dir}/virsh.sh

# #############################################################################
# This contains the data structures for the virtual topology.
# #############################################################################

# A seperator used in vars to specify records.
export RECORD_SEP="|"

# An array of the virtual machines.
vms=()

# An array of tuples of the virtual networks in the format $vnet|$vip|$vip6.
vnets=()

# An array of tuples of the virtual interfaces in the format:
#   $vm|$vnet|$vmac|$vip|$vip6.
vints=()

# An associative array of isos used by the various virtual machines keyed on
# the vm name.
declare -A isos

# An associative array of configs used by the various virtual machines keyed on
# the vm name.
declare -A configs

# An associative array of commands to be sent to the vm keyed on the vm name.
declare -A commands

# An associative array of packages used by the various virtual machines keyed on
# the vm name.
declare -A local_packages

# An associative array of remote packages used by the varius virtual machines
# keyed on the vm name.
declare -A remote_packages

# An associative array of vm types. Keyed on the virtual machine and returning
# the vm type.
declare -A vt_vm_types

# An associative array of vm types. Keyed on the type and returning a
# a string in the format $func1|$func2|...$funcN for type functions.
declare -A vt_vm_type_funcs

# #############################################################################
# Sets a virtual machine as a specific type for installation.
# #############################################################################
function vt_vm_type {
  local vm=$1
  local vmtype=$2

  echo "Setting the virtual topology vm $vm to a $vmtype vm."
  vt_vm_types[$vm]=$vmtype
}

# #############################################################################
# Create a new vm type.
# #############################################################################
function vt_vm_type_define {
  local vmtype=$1
  local install_image=$2
  local mgt=$3
  local load_config=$4
  local load_remote_packages=$5
  local load_local_packages=$6
  local run_commands=$7
  local console=$8
  local vm_commands=$9
  local s=$RECORD_SEP

  vt_vm_type_funcs[$vmtype]="$install_image$s$mgt$s$load_config$s$load_remote_packages$s$load_local_packages$s$run_commands$s$console$s$vm_commands"
}

# #############################################################################
# Executes a vm type function for the given function with the given arguments.
#
# Inputs:
#   vm: The virtual machine name.
#   func: The function to execute based on the type.
#   args: The arguments to pass to the function.
# #############################################################################
function vt_vm_type_execute {
  local vm=$1
  local func=$2
  local args="$3"

  if [ ${vt_vm_types[$vm]+isset} ] ; then
    # Parse the vm type record.
    local OLDIFS=$IFS
    IFS=$RECORD_SEP
    set ${vt_vm_type_funcs[${vt_vm_types[$vm]}]}
    local install_image=$1
    local mgt=$2
    local load_config=$3
    local load_remote_packages=$4
    local load_local_packages=$5
    local run_commands=$6
    local console=$7
    local vm_commands=$8
    IFS=$OLDIFS

    # Execute the type.
    case $func in
      install_image) $install_image $vm ;;
      mgt) $mgt $vm ;;
      load_config) $load_config $vm "$args" ;;
      load_remote_packages) $load_remote_packages $vm "$args" ;;
      load_local_packages) $load_local_packages $vm "$args" ;;
      run_commands) $run_commands $vm "$args" ;;
      console) $console $vm ;;
      vm_commands) $vm_commands "$args" ;;
      *) echo "Function Unknown" ;;
    esac
  else 
    echo "Unknown VM Type $vm"
  fi
}

# #############################################################################
# Installs the images on all vms in the virtual topology.
# #############################################################################
function vt_install_image_all_vms {
  echo "-------------------------"
  echo "Loading image on vms."

  for vm in "${vms[@]}" ; do
    vt_vm_type_execute $vm install_image
  done
}

# #############################################################################
# Configures eth0 as a mgmt port on all vms in the virtual topology.
# #############################################################################
function vt_mgt_all_vms {
  echo "-------------------------"
  echo "Loading mgt on vms."

  for vm in "${vms[@]}" ; do
    vt_vm_type_execute $vm mgt
  done
}

# #############################################################################
# Loads remote packages on all vms in the virtual topology.
# #############################################################################
function vt_load_remote_packages_all_vms {
  echo "-------------------------"
  echo "Loading remote packages on vms."

  for vm in "${vms[@]}" ; do
    if [ ${remote_packages[$vm]+isset} ] ; then
      local remote_package_list=${remote_packages[$vm]}
      vt_vm_type_execute $vm load_remote_packages "$remote_package_list"
    elif [[ -n "$global_remote_packages" ]] ; then
      vt_vm_type_execute $vm load_remote_packages "$global_remote_packages"
    fi
  done
}

# #############################################################################
# Loads local packages on all vms in the virtual topology.
# #############################################################################
function vt_load_local_packages_all_vms {
  echo "-------------------------"
  echo "Loading local packages on vms."

  for vm in "${vms[@]}" ; do
    if [ ${local_packages[$vm]+isset} ] ; then
      local local_package_list=${local_packages[$vm]}
      vt_vm_type_execute $vm load_local_packages "$local_package_list"
    elif [[ -n "$global_local_packages" ]] ; then
      vt_vm_type_execute $vm load_local_packages "$global_local_packages"
    fi
  done
}

# #############################################################################
# Runs the commands on all vms in the virtual topology.
# #############################################################################
function vt_run_commands_all_vms {
  echo "-------------------------"
  echo "Running commands on vms."

  for vm in "${vms[@]}" ; do
    if [ ${commands[$vm]+isset} ] ; then
      local cmds=${commands[$vm]}
      vt_vm_type_execute $vm run_commands "$cmds"
    fi
  done
}

# #############################################################################
# Loads configs on all vms in the virtual topology.
# #############################################################################
function vt_load_config_all_vms {
  echo "-------------------------"
  echo "Loading config on vms."

  for vm in "${vms[@]}" ; do
    if [ ${configs[$vm]+isset} ] ; then
      local config=${configs[$vm]}
      vt_vm_type_execute $vm load_config $config
    fi
  done
}

# #############################################################################
# Sets a config for a specific virtual machine.
# #############################################################################
function vt_vm_config {
  local vm=$1
  local config=$2

  echo "Setting the virtual topology vm $vm to use the config $config."
  configs[$vm]=$config
}

# #############################################################################
# Sets a set of commands for a specific virtual machine.
# #############################################################################
function vt_vm_commands {
  local vm=$1
  local cmds=$2

  echo "Setting the virtual topology vm $vm to execute commands."
  echo "$(printf '%s\n\n\n' "${cmds[@]}")" | tee $vt_logs_dir/vm_commands_${vm}.log
  commands[$vm]=$cmds
}

# #############################################################################
# Sets a list of local packages to load for a specific virtual machine.
# #############################################################################
function vt_vm_local_pkgs {
  local vm=$1
  local local_package_list=$2

  echo "Setting the virtual topology vm $vm to load local packages."
  local_packages[$vm]=$local_package_list
}

# #############################################################################
# Sets the local packages to be loaded on all vms.
# #############################################################################
function vt_local_pkgs {
  local local_package_list=$1
  local typ=$2

  echo "Setting the global local packages."
  
  for vmsi in $(eval echo {0..$((num_vms-1))}) ; do
    local vtyp=${vm_types[$vmsi]}
    if [[ -z $typ || "$typ" == "$vtyp" ]] ; then
      local_packages[${vms[$vmsi]}]=$local_package_list
    fi
  done
}

# #############################################################################
# Sets a list of remote packages to load for a specific virtual machine.
# #############################################################################
function vt_vm_remote_pkgs {
  local vm=$1
  local remote_package_list="$2"

  echo "Setting the virtual topology vm $vm to load remote packages."
  remote_packages[$vm]="$remote_package_list"
}

# #############################################################################
# Sets the remote packages to be loaded on all vms.
# #############################################################################
function vt_remote_pkgs {
  local remote_package_list=$1
  local typ="$2"

  echo "Setting the global remote packages."
  for vmsi in $(eval echo {0..$((num_vms-1))}) ; do
    local vtyp=${vm_types[$vmsi]}
    if [[ -z $typ || "$typ" == "$vtyp" ]] ; then
      remote_packages[${vms[$vmsi]}]=$remote_package_list
    fi
  done
}

# #############################################################################
# Constructs the virtual topology based on the virtual topology data structs.
# #############################################################################
function virtual_topology_construct {
  virtual_topology_pre_construct | tee $vt_logs_dir/virtual_topology_pre_construct.log
  virtual_topology_phy_construct | tee $vt_logs_dir/virtual_topology_phy_construct.log
  virtual_topology_construct_install | tee $vt_logs_dir/virtual_topology_construct_install.log
  virtual_topology_post_construct | tee $vt_logs_dir/virtual_topology_post_construct.log
}

# #############################################################################
# A hook for pre the construction.
# #############################################################################
function virtual_topology_pre_construct {
  if type virtual_topology_pre_construct_hook &> /dev/null ; then
    virtual_topology_pre_construct_hook
  fi
}

# #############################################################################
# A hook for post the construction.
# #############################################################################
function virtual_topology_post_construct {
  if type virtual_topology_post_construct_hook &> /dev/null ; then
    virtual_topology_post_construct_hook
  fi
}

# #############################################################################
# Constructs the virtual topology.
# #############################################################################
function virtual_topology_construct_install {
  echo "-------------------------"
  echo "Virtual topology construct install."

  vt_install_image_all_vms | tee $vt_logs_dir/vt_install_image_all_vms.log
  vt_mgt_all_vms | tee $vt_logs_dir/vt_mgt_all_vms.log
  vt_load_config_all_vms | tee $vt_logs_dir/vt_load_config_all_vms.log
  vt_load_remote_packages_all_vms | tee $vt_logs_dir/vt_load_remote_packages_all_vms.log
  vt_load_local_packages_all_vms | tee $vt_logs_dir/vt_load_local_packages_all_vms.log
  vt_run_commands_all_vms | tee $vt_logs_dir/vt_run_commands_all_vms.log
}

# #############################################################################
# Creates the vms and networks for the virtual topology.
# #############################################################################
function virtual_topology_phy_construct {
  echo "========================="
  echo "Creating all the virtual machines in the virtual topology."
  for vm in "${vms[@]}" ; do
    if [ ${isos[$vm]+isset} ] ; then
      local iso=${isos[$vm]}
    else
      local iso=$ISO
    fi
    case $iso in
      *qcow2)
        local dir=${VIRTUAL_MACHINE_IMAGE_DIR:-$LIBVIRT_IMAGES}
        local xml="${iso//qcow2/xml}" 
        local qcow2=$dir/$vm.qcow2
        local xmlt=`mktemp`
        rsync --progress $iso $qcow2
        cp $xml $xmlt

        xmlstarlet ed -L -u "//domain/devices/disk[@type='file']/source/@file" -v "$qcow2" $xmlt
        xmlstarlet ed -L -u "//domain/name" -v "$vm" $xmlt
        xmlstarlet ed -L -u "//domain/uuid" -v `uuid` $xmlt
        xmlstarlet ed -L -u "//domain/devices/interface/mac/@address" -v $build_mac $xmlt
        virsh define $xmlt
        /bin/rm $xmlt
        ;;
      *iso) virsh_define $vm $iso ;;
      *) echo "Unknown image type '$iso'" ;;
    esac
  done

  echo "========================="
  echo "Creating all the virtual networks in the virtual topology."
  for vnetrec in "${vnets[@]}" ; do
    local OLDIFS=$IFS
    IFS=$RECORD_SEP
    set $vnetrec
    local vnet=$1
    local vip=$2
    local vip6=$3
    virsh_net_define $vnet $vip $vip6
    virsh net-start $vnet # Need to start these for vint creation.
    IFS=$OLDIFS
    virsh_vnet_wait_until_active $vnet
  done

  echo "========================="
  echo "Creating all the virtual interfaces on the vms to the vnet."
  for vint in "${vints[@]}" ; do
    local OLDIFS=$IFS
    IFS=$RECORD_SEP
    set $vint
    local vm=$1
    local vnet=$2
    local vmac=$3
    local vip=$4
    local vip6=$5
    virsh_attach_interface $vm $vnet $vmac
    IFS=$OLDIFS
  done
}

# #############################################################################
# Enables the virtual topology based on the virtual topology data structs.
# #############################################################################
function virtual_topology_enable {
  echo "========================="
  echo "Enabling all networks in the virtual topology."
  for vnetrec in "${vnets[@]}" ; do
    local OLDIFS=$IFS
    IFS=$RECORD_SEP
    set $vnetrec
    local vnet=$1
    local vip=$2
    virsh net-start $vnet
    IFS=$OLDIFS
  done

  echo "========================="
  echo "Enabling all vms in the virtual topology."
  for vm in "${vms[@]}" ; do
    virsh start $vm
  done
}

# #############################################################################
# Disables the virtual topology based on the virtual topology data structs.
# #############################################################################
function virtual_topology_disable {
  echo "========================="
  echo "Disabling all vms in the virtual topology."
  for vm in "${vms[@]}" ; do
    if virsh_vm_is_created $vm ; then
      virsh destroy $vm
    fi
  done

  echo "========================="
  echo "Disabling all networks in the virtual topology.."
  for vnetrec in "${vnets[@]}" ; do
    local OLDIFS=$IFS
    IFS=$RECORD_SEP
    set $vnetrec
    local vnet=$1
    local vip=$2
    local vip6=$3
    virsh net-destroy $vnet
    IFS=$OLDIFS
  done
}

# #############################################################################
# Destructs the virtual topology based on the virtual topoloy data structs.
# #############################################################################
function virtual_topology_destruct {
  local dir=${VIRTUAL_MACHINE_IMAGE_DIR:-$LIBVIRT_IMAGES}
  virtual_topology_disable # Ensure the topology is entirely disabled before
                           # a destruct.

  echo "========================="
  echo "Destructing all virtual machines in the virtual topology."
  for vm in "${vms[@]}" ; do
    virsh undefine $vm
    if [ -f $dir/$vm.img ] ; then
      /bin/rm $dir/$vm.img
    fi
    
    if [ -f $dir/$vm.qcow2 ] ; then
      /bin/rm $dir/$vm.qcow2
    fi
  done

  echo "========================="
  echo "Destructing all networks in the virtual topology."
  for vnetrec in "${vnets[@]}" ; do
    local OLDIFS=$IFS
    IFS=$RECORD_SEP
    set $vnetrec
    local vnet=$1
    local vip=$2
    local vip6=$3
    virsh net-undefine $vnet
    IFS=$OLDIFS
  done
}

# #############################################################################
# Lists information pertaining to the virtual topology.
# #############################################################################
function virtual_topology_list {
  echo "========================="
  echo "Virtual Topology"
  echo "========================="

  for vm in "${vms[@]}" ; do
    echo "Virtual Machine \"$vm\""
    if virsh_vm_is_created $vm ; then
      virsh domiflist $vm | awk '{print "\t"$0}'
    fi
  done
}

# #############################################################################
# Declares a virtual topology virtual machine.
# #############################################################################
function vt_vm {
  local vm=$1

  echo "Adding vm $vm to the virtual topology."
  vms+=($vm)
}

# #############################################################################
# Declares a virtual topology virtual network.
# #############################################################################
function vt_vnet {
  local vnet=$1
  local vip=$2
  local vip6=$3

  echo "Adding network $vnet to the virtual topology with ip subnet $vip.0/24"\
    "and ip6 subnet $vip6::0/64."
  vnets+=("$vnet$RECORD_SEP$vip$RECORD_SEP$vip6")
}

# #############################################################################
# Declares a virtual topology virtual interface
# #############################################################################
function vt_vint {
  local vm=$1
  local vnet=$2
  local vmac=$3
  local vip=$4
  local vip6=$5

  echo "Adding an interface between $vm and $vnet with mac $vmac,"\
    "ip host byte $vip, ipv6 host bits $vip6 into the virtual topology."
  vints+=("$vm$RECORD_SEP$vnet$RECORD_SEP$vmac$RECORD_SEP$vip$RECORD_SEP$vip6")
}

# #############################################################################
# fetchs a url with wget.
# #############################################################################
function fetch {
  command -v wget >/dev/null 2>&1 || { echo >&2 "wget not found" ; return ; }
  if [ -n "$2" ] ; then
    local fname=$2
  else
    local fname=`basename ${1}`
  fi
  echo "Downloading from url $1."
  wget -O $fname -q -N --no-check-certificate ${1}
}

# #############################################################################
# takes and iso url and if its not a local file, e.g. http it fetchs said url.
# #############################################################################
function fetch_iso {
  local iso=$1
  if [[ $1 == http* ]] ; then
    local file=`mktemp`
    fetch $iso $file
  else
    local file=$iso
  fi
  echo $file
}

# #############################################################################
# Sets an iso for a specific virtual machine. This can take a http url at which
# point the iso will be downloaded from the given location.
# #############################################################################
function vt_vm_iso {
  local vm=$1
  local iso=`fetch_iso $2`

  echo "Setting the iso for vm $vm to $iso."
  isos[$vm]=$iso
}

# #############################################################################
# Sets the default virtual topology iso. This can take a http url at which point
# the iso will be downloaded from the given location.
# #############################################################################
function vt_iso {
  echo "Setting the global iso to $1."
  export ISO=`fetch_iso $1`
}

# #############################################################################
# Connects all the virtual machines to the default network. In general this
# function doesn't need to be used since devices are automatically connected
# to the default network.
# #############################################################################
function vt_vint_default_all {
  echo "Connecting all vms to the default network."
  for vm in "${vms[@]}" ; do
    vt_link $vm default
  done
}

