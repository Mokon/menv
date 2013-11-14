#!/bin/bash
#
# This file contains some wrappers around virsh.
#
# #############################################################################

# Directories
export LIBVIRT_IMAGES=/var/lib/libvirt/images
export LIBVIRT_XML=/etc/libvirt/qemu
export LIBVIRT_XML_NETS=/etc/libvirt/qemu/networks
export LIBVIRT_LOGS=/var/log/libvirt

# #############################################################################
# Sets the directory to store the vm images in.
# #############################################################################
function set_vm_img_dir {
  export VIRTUAL_MACHINE_IMAGE_DIR=$1
}

# #############################################################################
# Outputs a default route for the default network.
# #############################################################################
function default_route {
  xmlstarlet sel -t -v "//network/ip/@address" $LIBVIRT_XML_NETS/default.xml
}

# #############################################################################
# Creates a virtual machine with some default values.
#
# Inputs:
#   name: The name of the virtual machine.
#   iso: The location of an iso image to boot from for installation.
#   ram (optional): The amount of ram for the virtual machine.
#   vcpus (optional): The number of cpus for the virtual machine.
#   disk_size (optional): The disk size for the virtual machine.
# #############################################################################
function virsh_define {
  local name=$1
  local iso=$2
  local ram=${3:-4096}
  local vcpus=${4:-4}
  local disk_size=${5:-10}
  local dir=${VIRTUAL_MACHINE_IMAGE_DIR:-$LIBVIRT_IMAGES}

  echo "Creating a vm $name with the iso $iso with ram $ram, vcpus $vcpus, "\
    "and disk size $disk_size."

  mkdir -p $dir

  # TODO Convert this to using xml creation where we specifiy the pci bus etc
  # for nice naming of interfaces.

  virt-install \
               --connect=qemu:///system \
               --name=$name \
               --virt-type kvm \
               --description=$name \
               --arch=x86_64 \
               --vcpus=$vcpus \
               --ram=$ram \
               --os-type=linux \
               --os-variant=debianwheezy \
               --cdrom=$iso \
               --disk \
                 path=$dir/$name.img,size=$disk_size \
               --graphics none,keymap=en-us \
               --accelerate \
               --noautoconsole
}

# #############################################################################
# Attach a virtual machine to a network.
#
# Inputs:
#   vm: The name of the virtual machine to connect to the network.
#   net: The name of the network the virtual machine is connecting too.
#   mac: The mac address for the interface on the vm.
#   model (optional): The driver model use for this interface.
# #############################################################################
function virsh_attach_interface {
  local vm=$1
  local net=$2
  local mac=$3
  local model=${4:-virtio}

  echo "Attaching an interface from vm $vm to network $net with mac $mac "\
    "and driver $model."

  virsh attach-interface \
                         $vm \
                         --type network \
                         --source $net \
                         --mac $mac \
                         --model $model \
                         --persistent
}

# #############################################################################
# Creates a virtual network.
# #############################################################################
function virsh_net_define {
  local vnet=$1
  local vnet_ip=$2
  local vnet_ip6=$3

  echo "Creating a virtual network $vnet with ip subnet $vnet_ip.0/24 "\
    "and ipv6 subnet $vnet_ip6::0/64."

  # TODO remove vyatta.com
  local tmpfile=`mktemp`
  cat <<- XML > $tmpfile
    <network>
      <name>$vnet</name>
      <bridge name='v$vnet' stp='off' delay='0' />
      <domain name='vyatta.com'/>
      <ip address='X.X.X.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='X.X.X.128' end='X.X.X.254' />
       </dhcp>
      </ip>
      <ip family="ipv6" address="$vnet_ip6::1" prefix="64" >
        <dhcp>
          <range start="X::0F" end="X::FF" />
        </dhcp>
      </ip>
    </network>
XML

  xmlstarlet ed -L -u "//network/ip[not(@family='ipv6')]/@address" -v "$vnet_ip.1" $tmpfile
  xmlstarlet ed -L -u "//network/ip[not(@family='ipv6')]/dhcp/range/@start" -v "$vnet_ip.128" $tmpfile
  xmlstarlet ed -L -u "//network/ip[not(@family='ipv6')]/dhcp/range/@end" -v "$vnet_ip.254" $tmpfile

  xmlstarlet ed -L -u "//network/ip[@family='ipv6']/@address" -v "$vnet_ip6::1" $tmpfile
  xmlstarlet ed -L -u "//network/ip[@family='ipv6']/dhcp/range/@start" -v "$vnet_ip6::0F" $tmpfile
  xmlstarlet ed -L -u "//network/ip[@family='ipv6']/dhcp/range/@end" -v "$vnet_ip6::FF" $tmpfile

  for vint in "${vints[@]}" ; do
    local OLDIFS=$IFS
    IFS=$RECORD_SEP
    set $vint
    local rvm=$1
    local rvnet=$2
    local rvmac=$3
    local rvip=$4
    local rvip6=$5

    if [[ $vnet == $rvnet ]] ; then
      xmlstarlet ed -L -s "//network/ip[not(@family='ipv6')]/dhcp" \
        -t elem -name host -v "" $tmpfile
      xmlstarlet ed -L -i "//network/ip[not(@family='ipv6')]/dhcp/host[not(@mac)]" \
        -t attr -name mac -v "$rvmac" $tmpfile
      xmlstarlet ed -L -i "//network/ip[not(@family='ipv6')]/dhcp/host[@mac='$rvmac']" \
        -t attr -name ip -v "$vnet_ip.$rvip" $tmpfile
      xmlstarlet ed -L -i "//network/ip[not(@family='ipv6')]/dhcp/host[@mac='$rvmac']" \
        -t attr -name name -v "$rvm" $tmpfile

      xmlstarlet ed -L -s "//network/ip[@family='ipv6']/dhcp" \
        -t elem -name host -v "" $tmpfile
      xmlstarlet ed -L -i "//network/ip[@family='ipv6']/dhcp/host[not(@name)]" \
        -t attr -name name -v "$rvm" $tmpfile
      xmlstarlet ed -L -i "//network/ip[@family='ipv6']/dhcp/host[@name='$rvm']" \
        -t attr -name ip -v "$vnet_ip6::$rvip6" $tmpfile

      xmlstarlet ed -L -s "//network[not(dns)]" -t elem -name dns -v "" $tmpfile
      xmlstarlet ed -L -s "//network/dns" -t elem -name host -v "" $tmpfile
      xmlstarlet ed -L -i "//network/dns/host[not(@ip)]" \
        -t attr -name ip -v "$vnet_ip.$rvip" $tmpfile
      xmlstarlet ed -L -s "//network/dns/host[@ip='$vnet_ip.$rvip']" \
        -t elem -name hostname -v "$rvm" $tmpfile

      xmlstarlet ed -L -s "//network/dns" -t elem -name host -v "" $tmpfile
      xmlstarlet ed -L -i "//network/dns/host[not(@ip)]" \
        -t attr -name ip -v "$vnet_ip6::$rvip6" $tmpfile
      xmlstarlet ed -L -s "//network/dns/host[@ip='$vnet_ip6::$rvip6']" \
        -t elem -name hostname -v "$rvm" $tmpfile
    fi

    IFS=$OLDIFS
  done

  virsh net-define $tmpfile
  virsh net-autostart --network $vnet
  cat $tmpfile
  rm $tmpfile
}

# #############################################################################i
# Displays some information about the virsh environment.
# #############################################################################
function virsh_list {
  echo "Listing information from virsh."
  virsh list --all
  virsh net-list --all
  virsh iface-list --all
}

# #############################################################################
# Returns whether or not a vm is running.
# #############################################################################
function virsh_vm_is_running {
  local vm=$1

  virsh list --all | grep "$vm " |grep "running" &> /dev/null # Space Important!
  return $?
}

# #############################################################################
# Returns whether or not a vm has been created.
# #############################################################################
function virsh_vm_is_created {
  local vm=$1

  virsh list --all | grep "$vm " &> /dev/null # Space Important!
  return $?
}

# #############################################################################
# Waits until the given vm is running.
# #############################################################################
function virsh_vm_wait_until_running {
  local vm=$1
    
  if ! virsh_vm_is_running $vm ; then
    virsh start $vm
  fi

  while : ; do
    if virsh_vm_is_running $vm ; then
      break
    fi
    sleep 1
  done
}

# #############################################################################
# Waits until the given vnetwork is active
# #############################################################################
function virsh_vnet_wait_until_active {
  local vnet=$1

  while : ; do
    virsh net-list --all | grep "$vnet " |grep "active" # <-- Space Important!
    ret=$?
    if [[ $ret == 0 ]] ; then
      break
    fi
    sleep 1
  done
}

# #############################################################################
# Waits until the given vm is pingable on the default (or given) network
# #############################################################################
function virsh_vm_wait_until_pingable {
  local vm=$1
  local vnet=${4:-"default"}

  virsh_vm_wait_until_running $vm

  while : ; do
    local vmip=$(perl -w $menv_scripts_dir/vt/virt-addr $vm $vnet)
    if ! ping -c1 $vmip &> /dev/null ; then break ; fi
  done 
}

