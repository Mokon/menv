#!/bin/bash
#
# This file contains functionality around generic vm specific interactions with
# the virtual topology being generated. This file can be used as a template
# to generate new types.
#
# #############################################################################

# Define the virtual machine type.
vt_vm_type_define vm vm_install_image vm_mgt vm_load_config \
  vm_load_remote_packages vm_load_local_packages vm_run_commands vm_console \
  vm_vm_commands

# #############################################################################
# Installs an image on the given vm.
# #############################################################################
function vm_install_image {
  local vm=$1

  echo "Virtual topology vm $vm installing image."

  echo "NOT IMPLEMENTED"
}

# #############################################################################
# Configures eth0 as a mgt port on the given vm.
# #############################################################################
function vm_mgt {
  local vm=$1

  echo "Virtual topology vm $vm mgt port eth0."

  echo "NOT IMPLEMENTED"
}

# #############################################################################
# Loads a given config on the given vm.
# #############################################################################
function vm_load_config {
  local vm=$1
  local config=$2

  echo "Virtual topology vm $vm loading config."

  echo "NOT IMPLEMENTED"
}

# #############################################################################
# Runs the given commands on the given vms.
# #############################################################################
function vm_run_commands {
  local vm=$1
  local cmds=$2

  echo "Virtual topology vm $vm running commands."

  echo "NOT IMPLEMENTED"
}

# #############################################################################
# Loads a given local package list on the given vm.
# #############################################################################
function vm_load_local_packages {
  local vm=$1
  local local_packages=$2

  echo "Virtual topology vm $vm loading local packages."

  echo "NOT IMPLEMENTED"
}

# #############################################################################
# Loads a given remote package list on the given vm.
# #############################################################################
function vm_load_remote_packages {
  local vm=$1
  local remote_packages=$2

  echo "Virtual topology vm $vm loading remote packages."

  echo "NOT IMPLEMENTED"
}

# #############################################################################
# Consoles into the virtual device.
# #############################################################################
function vm_console {
  local vm=$1

  echo "Virtual topology vm $vm console."

  echo "NOT IMPLEMENTED"
}

# #############################################################################
# Sets up all the vm virtual topology commands.
# #############################################################################
function vm_vm_commands {
  local vmsi=$1

  echo "Virtual topology vm $vm vm commands."

  echo "NOT IMPLEMENTED"
}

