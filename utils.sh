#!/bin/bash
NC="\033[0m"
WHITE="\033[1;37m"
BLUE="\033[0;34m"
GREEN="\033[0;32m"

function MV {
  echo -e "\t$1 $2 $3"
  $1 $2 $3
}

function check_array {
  declare -p $1 | grep -q '^declare \-a' && return 0 || return 1
}

function check_input {
  local l=($1)
  local LIST=($2)
  for pkg in "${l[@]}"; do
    ret=0
    for el in "${LIST[@]}"; do
      if [ $pkg == $el ]; then
        ret=$(( $ret | 1 ))
      fi
    done
    if [ $ret == 0 ]; then
      echo "Package $pkg not between possibilities"
      exit -1
    fi
  done
}

function in_list {
  local LIST=($1)
  local el=$2
  for v in "${LIST[@]}"; do 
    if [ $el == $v ]; then
      return 0
    fi
  done 
  return 1
}

function remove {
  local LIST=($1)
  local el=$2
  ret=()
  for v in "${LIST[@]}"; do
    if [ ! $v == $el ]; then
      ret+=($v)
    fi
  done
  echo "${ret[*]}"
}
