#!/bin/bash -xv
#
my_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${my_dir}/utils.sh

KUBECTL=$(locate_kubectl)
if [ $? -ne 0 ]; then
   exit 1
fi
echo "found kubectl at: ${KUBECTL}"
