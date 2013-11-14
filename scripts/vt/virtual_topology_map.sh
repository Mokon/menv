#!/bin/bash
#
# This file creation of a map of the virtual topology.
#
# #############################################################################

# #############################################################################
# Prints to a given file $1 the given text $2 by appending it to the end.
# 
# Inputs:
#   text: The text to append to the file.
#   file: The file path to append to.
# 
# #############################################################################
function fp {
  echo $2 >> $1
}

# #############################################################################
# Generates a png map of the virtual topology. This uses graphviz for the
# generation.
# #############################################################################
function virtual_topology_generate_map {
  local out=${1:-vt.png}
  local in=`mktemp`
 
  fp $in "digraph virtual_topology {"

  fp $in "nodesep=2;"
  fp $in "ranksep=4;"

  # Add vnets
  for vnetrec in "${vnets[@]}" ; do
    local OLDIFS=$IFS
    IFS=$RECORD_SEP
    set $vnetrec
    local vnet=$1
    local vip=$2
    local vip6=$3
  
    # Add vints
    for vint in "${vints[@]}" ; do
      set $vint
      local ivm=$1
      local ivnet=$2
      local ivmac=$3
      local ivip=$4
      local ivip6=$5
   
      if [[ $vnet == $ivnet ]] ; then
        fp $in "$ivm -> $ivnet  [label=\"$ivmac\n$vip.$ivip\n$vip6::$ivip6\"]"
      fi
    done

    IFS=$OLDIFS
  done
  
  # Add vnets
  for vnetrec in "${vnets[@]}" ; do
    local OLDIFS=$IFS
    IFS=$RECORD_SEP
    set $vnetrec
    local vnet=$1
    local vip=$2
    local vip6=$3
    fp $in "$vnet [shape=circle, label=\"$vnet\n$vip.0/24\n $vip6::0/64\", fillcolor=\"#ABACBA\", style=filled]"
    IFS=$OLDIFS
  done
   
  # Add vms
  for vm in "${vms[@]}" ; do
    fp $in "$vm [shape=box, label=\"$vm\", fillcolor=\"#ABACBA\", style=filled]"
  done

  fp $in "}"

  dot $in -Tpng -o $out
  rm $in
}

