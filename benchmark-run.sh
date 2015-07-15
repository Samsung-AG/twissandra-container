#!/bin/bash  
#
# Script to start all the pieces of the twissandra benchmark
# requires a cassandra cluster running as a kubernetes service
# uses jq to parse json returns
#
# 4/22/2015 mikeln
#-------
#
VERSION="1.0"
function usage
{
    echo "Runs cassandra client - Benchmark"
    echo ""
    echo "Usage:"
    echo "   benchmak-run.sh [flags]"
    echo ""
    echo "Flags:"
    echo "  -n, --noschema :: Flag to avoid running the schema creation step"
    echo "  -c, --cluster : local : [local, aws, ???] selects the cluster yaml/json to use"
    echo "  -h, -?, --help :: print usage"
    echo "  -v, --version :: print script verion"
    echo ""
}
function version
{
    echo "benchmark-run.sh version $VERSION"
}
# some best practice stuff
CRLF=$'\n'
CR=$'\r'
unset CDPATH

# XXX: this won't work if the last component is a symlink
my_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${my_dir}/utils.sh

#
echo " "
echo "=================================================="
echo "   Attempting to Start the"
echo "   Twissandra Kubernetes Demo"
echo "   version: $VERSION"
echo "=================================================="
echo "  !!! NOTE  !!!"
echo "  This script uses our kraken project assumptions:"
echo "     kubectl will be located at (for OS-X):"
echo "       /opt/kubernetes/platforms/darwin/amd64/kubectl"
echo " "
echo "  jq must be installed"
echo " "
echo "  Your Kraken Kubernetes Cluster Must be"
echo "  up and Running.  "
echo ""
echo "  And you must have your ~/.kube/config for you cluster set up.  e.g."
echo " "
echo "  local: kubectl config set-cluster local --server=http://172.16.1.102:8080 "
echo "  aws:   kubectl config set-cluster aws --server=http:////52.25.218.223:8080 "
echo "=================================================="
#----------------------
# start the services first...this is so the ENV vars are available to the pods
#----------------------
# process args
#
CLUSTER_LOC="local"
CREATE_SCHEMA="y"
TMP_LOC=$CLUSTER_LOC
while [ "$1" != "" ]; do
    case $1 in
        -c | --cluster )
            shift
            TMP_LOC=$1
            ;;
        -n | --noschema )
            CREATE_SCHEMA="n"
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
echo "Using Kubernetes cluster: $CLUSTER_LOC create schema: $CREATE_SCHEMA"
#
# setup trap for script signals
#
trap "echo ' ';echo ' ';echo 'SIGNAL CAUGHT, SCRIPT TERMINATING, cleaning up'; . ./benchmark-down.sh --cluster $CLUSTER_LOC; exit 9 " SIGHUP SIGINT SIGTERM
#
# check for required additional BASH app to parse json: 'jq'
#
which jq
if [ $? -ne 0 ];then
   echo "ERROR! jq is not accessible.  Please install it and make sure it is on your PATH"
   exit 8
fi
#
# check to see if kubectl has been configured
#
echo " "
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
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running?"
    exit 1;
else
    echo "kubectl present: $kubectl_local"
fi
echo " "
# get minion IPs for later...also checks if cluster is up
echo "+++++ finding Kubernetes Nodes services ++++++++++++++++++++++++++++"
NODEIPS=""
NODERET=$($kubectl_local get nodes --output=json  2>/dev/null)
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running? Did you set the correct values in your ~/.kube/config file for ${CLUSTER_LOC}?"
    exit 1;
else
    #
    # TODO: should probably validate that the status is Ready for the minions.  low level concern 
    #
    #parset the json returned
    NODEIPS=$( echo ${NODERET} | jq '.items[].metadata.name' | tr -d "\"" )
    #
    # TODO: may need to eval the return
    #
    echo "Kubernetes minions (nodes) IP(s):"
    for ip in $NODEIPS;do
        echo "   $ip "
    done
fi
echo " "
echo "+++++ checking for cassandra services ++++++++++++++++++++++++++++"
$kubectl_local get services cassandra 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Cassandra service not running.  Please start a cassandra cluster."
    exit 2
else
    echo "Found Cassandra service."
fi
echo " "
echo "Services List:"
$kubectl_local get services
echo " "
if [ "$CREATE_SCHEMA" = "y" ]; then
    echo "+++++ Creating Needed Twissandra Schema ++++++++++++++++++++++++++++"
    #
    # check if already there... delete it in any case.  
    # (if it was finished, ok.  if pending, ok, if running...we'll run again anyway)
    #
    $kubectl_local get pods dataschema 2>/dev/null
    if [ $? -eq 0 ];then
        #
        # already there... delete it
        #
        echo "Twissandra dataschema pod alread present...deleting"
        $kubectl_local delete pods dataschema 2>/dev/null
        if [ $? -ne 0 ]; then
            # problem with delete...ignore?
            echo "Error deleting Twissandra dataschema pod...ignoring"
        fi
    fi
    # start a new one
    # 
    # find yaml for correct target
    #
    DATASCHEMA_POD_BASE_NAME="kubernetes/dataschema"
    DATASCHEMA_YAML="$DATASCHEMA_POD_BASE_NAME-$CLUSTER_LOC.yaml"
    if [ ! -f "$DATASCHEMA_YAML" ]; then
        echo "WARNING $DATASCHEMA_YAML not found.  Using $DATASCHEMA_POD_BASE_NAME.yaml instead."
        DATASCHEMA_YAML="$DATASCHEMA_POD_BASE_NAME.yaml"
    fi

    $kubectl_local create -f $DATASCHEMA_YAML 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Twissandra dataschema pod error"
        . ./benchmark-down.sh --cluster $CLUSTER_LOC
        # clean up the potential mess
        exit 3
    else
        echo "Twissandra dataschema pod started"
    fi
    #
    # Wait until it finishes before proceeding
    #
    # allow 10 minutes for these to come up (120*5=600 sec)
    NUMTRIES=120
    LASTRET=1
    LASTSTATUS="unknown"
    while [ $NUMTRIES -ne 0 ] && ( [ "$LASTSTATUS" != "Succeeded" ] && [ "$LASTSTATUS" != "Failed" ] ); do
        let REMTIME=NUMTRIES*5
        LASTSTATUS_RET=$($kubectl_local get pods dataschema --output=json 2>/dev/null)
        LASTRET=$?
        if [ $? -ne 0 ]; then
            echo -n "Twissandra dataschema pod not found $REMTIME"
            D=$NUMTRIES
            while [ $D -ne 0 ]; do
                echo -n "."
                let D=D-1
            done
            echo -n "  $CR"
            LASTSTATUS="unknown"
            let NUMTRIES=NUMTRIES-1
            sleep 5
        else
            LASTSTATUS=$( echo ${LASTSTATUS_RET} | jq '.status.phase' | tr -d "\"" )
            #echo "Twissandra pod found $LASTSTATUS"
            if [ "$LASTSTATUS" = "Failed" ]; then
                echo ""
                echo "Twissandra datachema pod: Failed!"
            elif [ "$LASTSTATUS" = "Succeeded" ]; then
                echo ""
                echo "Twissandra datachema pod finished!"
            else
                echo -n "Twissandra datachema pod: $LASTSTATUS - NOT Succeeded $REMTIME secs remaining"
                let D=NUMTRIES/2
                while [ $D -ne 0 ]; do
                    echo -n "."
                    let D=D-1
                done
                echo -n "  $CR"
                let NUMTRIES=NUMTRIES-1
                sleep 5
            fi
        fi
    done
    echo ""
    if [ $NUMTRIES -le 0 ] || [ "$LASTSTATUS" = "Failed" ]; then
        echo "Twissandra dataschema pod did not finish in alotted time...exiting"
        # clean up the potential mess
        . ./benchmark-down.sh --cluster $CLUSTER_LOC
        exit 3
    fi
    #
    # now delete the pod ... it was successful and one-shot
    #
    $kubectl_local delete pods dataschema 2>/dev/null
    if [ $? -ne 0 ]; then
        # problem with delete...ignore?
        echo "Error deleting Twissandra dataschema pod...ignoring"
    fi
    echo " "
fi
echo "+++++ Run the Benchmark ++++++++++++++++++++++++++++"
#
# check if already there... delete it in any case.  
# (if it was finished, ok.  if pending, ok, if running...we'll run again anyway)
#
$kubectl_local get pods benchmark 2>/dev/null
if [ $? -eq 0 ];then
    #
    # already there... delete it
    #
    echo "Twissandra benchmark pod alread present...deleting"
    $kubectl_local delete pods benchmark 2>/dev/null
    if [ $? -ne 0 ]; then
        # problem with delete...ignore?
        echo "Error deleting Twissandra benchmark pod...ignoring"
    fi
fi
# start a new one
# 
# find yaml for correct target
#
BENCHMARK_POD_BASE_NAME="kubernetes/benchmark"
BENCHMARK_YAML="$BENCHMARK_POD_BASE_NAME-$CLUSTER_LOC.yaml"
if [ ! -f "$BENCHMARK_YAML" ]; then
    echo "WARNING $BENCHMARK_YAML not found.  Using $BENCHMARK_POD_BASE_NAME.yaml instead."
    BENCHMARK_YAML="$BENCHMARK_POD_BASE_NAME.yaml"
fi

$kubectl_local create -f $BENCHMARK_YAML 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Twissandra benchmark pod error"
    . ./benchmark-down.sh --cluster $CLUSTER_LOC
    # clean up the potential mess
    exit 3
else
    echo "Twissandra benchmark pod started"
fi
#
# Wait until it finishes before proceeding
#
# allow 10 minutes for these to come up (120*5=600 sec)
NUMTRIES=120
LASTRET=1
LASTSTATUS="unknown"
STARTTIME=0
CURTIME=0
ENDTIME=0
while [ $NUMTRIES -ne 0 ] && [ "$LASTSTATUS" != "Succeeded" ] && [ "$LASTSTATUS" != "Failed" ]; do
    let REMTIME=NUMTRIES*5
    LASTSTATUS_RET=$($kubectl_local get pods benchmark --output=json 2>/dev/null)
    LASTRET=$?
    if [ $? -ne 0 ]; then
        echo -n "Twissandra benchmark pod not found $REMTIME"
        D=$NUMTRIES
        while [ $D -ne 0 ]; do
            echo -n "."
            let D=D-1
        done
        echo -n "  $CR"
        LASTSTATUS="unknown"
        let NUMTRIES=NUMTRIES-1
        sleep 5
    else
        LASTSTATUS=$( echo ${LASTSTATUS_RET} | jq '.status.phase' | tr -d "\"" )
        #echo "Twissandra pod found $LASTSTATUS"
        if [ "$LASTSTATUS" = "Failed" ]; then
            echo ""
            echo "Twissandra benchmark pod failed!"
        elif [ "$LASTSTATUS" = "Succeeded" ]; then
            echo ""
            echo "Twissandra benchmark pod finished!"
        elif [ "$LASTSTATUS" = "Running" ]; then
            #
            # calculate time
            if [ $STARTTIME -eq 0 ]; then
                STARTTIME=$(date +%s)
                echo ""
            fi
            CURTIME=$(date +%s)
            echo -n "Twissandra Benchmard Inject Running: $(($CURTIME-$STARTTIME)) +/-10 seconds $CR"
            sleep 5
        else
            echo -n "Twissandra benchmark pod: $LASTSTATUS - NOT Succeeded $REMTIME secs remaining"
            let D=NUMTRIES/2
            while [ $D -ne 0 ]; do
                echo -n "."
                let D=D-1
            done
            echo -n "  $CR"
            let NUMTRIES=NUMTRIES-1
            sleep 5
        fi
    fi
done
ENDTIME=$(date +%s)
echo ""
if [ $NUMTRIES -le 0 ] || [ "$LASTSTATUS" = "Failed" ]; then
    echo "Twissandra benchmark pod did not start in alotted time...exiting"
    # clean up the potential mess
    . ./benchmark-down.sh --cluster $CLUSTER_LOC
    exit 3
fi
#
# now delete the pod ... it was successful and one-shot
#
$kubectl_local delete pods benchmark 2>/dev/null
if [ $? -ne 0 ]; then
    # problem with delete...ignore?
    echo "Error deleting Twissandra benchmark pod...ignoring"
fi
echo " "
echo "Pods:"
$kubectl_local get pods
echo " "
#
# git the user the correct URLs for opscenter and connecting that to the cluster
#
echo "===================================================================="
echo " "
echo "  Twissandra Benchmark has finished!"
echo "     elapsed run time: $(($ENDTIME - $STARTTIME)) +/-10 seconds "
echo " "
echo "===================================================================="
echo "+++++ twissandra started in Kubernetes ++++++++++++++++++++++++++++"
