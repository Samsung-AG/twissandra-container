#!/bin/bash 
#
# Script to stop all the pieces of the twissandra cluster benchmark
#
#-------
VERSION="1.0"
function usage
{
    echo "Stops benchmark"
    echo ""
    echo "Usage:"
    echo "   benchmark-down.sh [flags]"
    echo ""
    echo "Flags:"
    echo "  -c, --cluster : local : [local, aws, ???] selects the cluster yaml/json to use"
    echo "  -h, -?, --help :: print usage"
    echo "  -v, --version :: print script verion"
    echo ""
}
function version
{
    echo "benchmark-down.sh version $VERSION"
}

# some best practice stuff
unset CDPATH

# XXX: this won't work if the last component is a symlink
my_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${my_dir}/utils.sh

#
echo " "
echo "=================================================="
echo "   Attempting to Stop and Delete the"
echo "   Twissandra Kubernetes Benchmark"
echo "=================================================="
#----------------------
# start the services first...this is so the ENV vars are available to the pods
#----------------------
CLUSTER_LOC="local"
TMP_LOC=$CLUSTER_LOC
while [ "$1" != "" ]; do
    case $1 in
        -c | --cluster )
            shift
            TMP_LOC=$1
            ;;
        -v | --version )
            version
            exit
            ;;
        -h | -? | --help )
            usage
            exit
            ;;
         * )
             usage
             exit 1
    esac
    shift
done
if [ -z "$TMP_LOC" ];then
    echo ""
    echo "ERROR No Cluster Supplied."
    echo ""
    usage
    exit 1
else
    CLUSTER_LOC=$TMP_LOC
fi
echo "Using Kubernetes cluster: $CLUSTER_LOC"
#
# check to see if kubectl has be configured
#
echo " "
echo "Locating kubectl and .kubeconfig..."
SCRIPTPATH="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
cd ${SCRIPTPATH}
DEVBASE=${SCRIPTPATH%/twissandra-container}
echo "DEVBASE ${DEVBASE}"
#
# locate projects...
#
KRAKENDIR=`find ${DEVBASE} -type d -name "kraken" -print | egrep '.*'`
if [ $? -ne 0 ];then
    echo "Could not find the Kraken project."
    exit 1
else
    echo "found: $KRAKENDIR"
fi

KUBECTL=$(locate_kubectl)
if [ $? -ne 0 ]; then
  exit 1
fi
echo "found kubectl at: ${KUBECTL}"

# XXX: kubectl doesn't seem to provide an out-of-the-box way to ask if a cluster
#      has already been set so we just assume it's already been configured, eg:
#
#      kubectl config set-cluster local --server=http://172.16.1.102:8080 
kubectl_local="${KUBECTL} --cluster=${CLUSTER_LOC}"

CMDTEST=`$kubectl_local version`   
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running? (Hint: vagrant status, vagrant up)"
    exit 1;
else
    echo "kubectl present: $kubectl_local"
fi
echo " "
echo "+++++ stopping twissandra pods ++++++++++++++++++++++++++++"
$kubectl_local delete pods dataschema 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Twissandra dataschema pods already down"
else
    echo "Twissandra dataschema pods deleted"
fi
$kubectl_local delete pods benchmark 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Twissandra benchmark pods already down"
else
    echo "Twissandra benchmark pods deleted"
fi
echo " "
echo "Remaining Pods:"
$kubectl_local get pods
echo " "
echo "+++++ twissandra benchmark stopped and deleted from Kubernetes ++++++++++++++++++++++++++++"
