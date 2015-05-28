#!/bin/bash 
#
# Script to start all the pieces of the twissandra demo
# requires a cassandra cluster running as a kubernetes service
#
# 4/20/2015 mikeln
#-------
#
VERSION="1.0"
function usage
{
    echo "Runs cassandra client - Twissandra"
    echo ""
    echo "Usage:"
    echo "   webui-run.sh [flags]"
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
    echo "webui-run.sh version $VERSION"
}
# some best practice stuff
CRLF=$'\n'
CR=$'\r'
unset CDPATH
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
echo "    .kubeconfig is from our kraken project"
echo " "
echo "  Your Kraken Kubernetes Cluster Must be"
echo "  up and Running.  "
echo ""
echo "  And you must have your ~/.kube/config for you cluster set up.  e.g."
echo " "
echo "  local: kubectl config set-cluster local --server=http://172.16.1.102:8080 --api-version=v1beta3"
echo "  aws:   kubectl config set-cluster aws --server=http:////52.24.103.52:8080 --api-version=v1beta3"
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
    echo "ERROR No Cluster Supplied"
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
trap "echo ' ';echo ' ';echo 'SIGNAL CAUGHT, SCRIPT TERMINATING, cleaning up'; . ./webui-down.sh --cluster $CLUSTER_LOC; exit 9 " SIGHUP SIGINT SIGTERM
#
# check to see if kubectl has been configured
#
echo " "
echo "Locating Kraken Project kubectl and .kubeconfig..."
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
#
# note this has changed.  it assumes that you correctly set your env after your cluster came up
#
#KUBECONFIG=`find ${KRAKENDIR}/kubernetes/${CLUSTER_LOC} -type f -name ".kubeconfig" -print | egrep '.*'`
#if [ $? -ne 0 ];then
#    echo "Could not find ${KRAKENDIR}/kubernetes/${CLUSTER_LOC}/.kubeconfig"
#    exit 1
#else
#    echo "found: $KUBECONFIG"
#fi

KUBECTL=`find /opt/kubernetes/platforms/darwin/amd64 -type f -name "kubectl" -print | egrep '.*'`
if [ $? -ne 0 ];then
    echo "Could not find kubectl."
    exit 1
else
    echo "found: $KUBECTL"
fi

#kubectl_local="/opt/kubernetes/platforms/darwin/amd64/kubectl --kubeconfig=/Users/mikel_nelson/dev/cloud/kraken/kubernetes/.kubeconfig"
#kubectl_local="${KUBECTL} --kubeconfig=${KUBECONFIG}"
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
NODEIPS=`$kubectl_local get nodes --output=template --template="{{range $.items}}{{.metadata.name}}${CRLF}{{end}}" 2>/dev/null`
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running? Did you set the correct values in your ~/.kube/config file for ${CLUSTER_LOC}?"
    exit 1;
else
    #
    # TODO: should probably validate that the status is Ready for the minions.  low level concern 
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
#
# start the twissandra service first
#
$kubectl_local get services twissandra 2>/dev/null
if [ $? -ne 0 ]; then
    #
    # find yaml for correct target
    #
    TWISSANDRA_SERVICE_BASE_NAME="kubernetes/twissandra-service"
    TWISSANDRA_SERVICE_YAML="$TWISSANDRA_SERVICE_BASE_NAME-$CLUSTER_LOC.yaml"
    if [ ! -f "$TWISSANDRA_SERVICE_YAML" ]; then
        echo "WARNING $TWISSANDRA_SERVICE_YAML not found.  Using $TWISSANDRA_SERVICE_BASE_NAME.yaml instead."
        TWISSANDRA_SERVICE_YAML="$TWISSANDRA_SERVICE_BASE_NAME.yaml"
    fi

    $kubectl_local create -f $TWISSANDRA_SERVICE_YAML 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Twissandra service start error"
        . ./webui-down.sh --cluster $CLUSTER_LOC
        # clean up the potential mess
        exit 2
    else
        echo "Twissandra service started"
        #
        # wait until services are ready
        #
        NUMTRIES=4
        LASTRET=1
        while [ $LASTRET -ne 0 ] && [ $NUMTRIES -ne 0 ]; do
            $kubectl_local get services twissandra 2>/dev/null
            LASTRET=$?
            if [ $LASTRET -ne 0 ]; then
                echo "Twissandra service not found $NUMTRIES"
                let NUMTRIES=NUMTRIES-1
                sleep 1
            else
                echo "Twissandra service found"
            fi
        done
        if [ $NUMTRIES -le 0 ]; then
            echo "Twissandra Service did not start in alotted time...exiting"
            # clean up the potential mess
            . ./webui-down.sh --cluster $CLUSTER_LOC
            exit 2
        fi
    fi
else
    echo "Twissandra service already running...skipping"
fi
#
#
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
        . ./webui-down.sh --cluster $CLUSTER_LOC
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
    while [ $NUMTRIES -ne 0 ] && [ "$LASTSTATUS" != "Succeeded" ] && [ "$LASTSTATUS" != "Failed" ]; do
        let REMTIME=NUMTRIES*5
        LASTSTATUS=`$kubectl_local get pods dataschema --output=template --template={{.status.phase}} 2>/dev/null`
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
            #echo "Twissandra pod found $LASTSTATUS"
            if [ "$LASTSTATUS" = "Failed" ]; then
                echo ""
                echo "Twissandra datachema pod failed!"
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
        . ./webui-down.sh --cluster $CLUSTER_LOC
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
echo "+++++ starting Twissandra pod ++++++++++++++++++++++++++++"
#
# check if things are already running..and skip
#
$kubectl_local get pods twissandra 2>/dev/null
if [ $? -ne 0 ];then
    # start a new one
    #
    # find yaml for correct target
    #
    BENCHMARK_POD_BASE_NAME="kubernetes/twissandra"
    BENCHMARK_YAML="$BENCHMARK_POD_BASE_NAME-$CLUSTER_LOC.yaml"
    if [ ! -f "$BENCHMARK_YAML" ]; then
        echo "WARNING $BENCHMARK_YAML not found.  Using $BENCHMARK_POD_BASE_NAME.yaml instead."
        BENCHMARK_YAML="$BENCHMARK_POD_BASE_NAME.yaml"
    fi
    $kubectl_local create -f $BENCHMARK_YAML 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Twissandra pod error"
        . ./webui-down.sh --cluster $CLUSTER_LOC
        # clean up the potential mess
        exit 3
    else
        echo "Twissandra pod started"
    fi
else
    echo "Twissandra pod is already present...skipping"
fi
echo " "
echo "Pods:"
$kubectl_local get pods
echo ""
echo "Waiting for all needed pods to indicate Running"
echo ""
#
# wait for pods start
#
# allow 10 minutes for these to come up (120*5=600 sec)
NUMTRIES=120
LASTRET=1
LASTSTATUS="unknown"
while [ $NUMTRIES -ne 0 ] && [ "$LASTSTATUS" != "Running" ]; do
    let REMTIME=NUMTRIES*5
    LASTSTATUS=`$kubectl_local get pods twissandra --output=template --template={{.status.phase}} 2>/dev/null`
    LASTRET=$?
    if [ $? -ne 0 ]; then
        echo -n "Twissandra pod not found $REMTIME"
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
        #echo "Twissandra pod found $LASTSTATUS"
        if [ "$LASTSTATUS" != "Running" ]; then
            echo -n "Twissandra pod: $LASTSTATUS - NOT running $REMTIME secs remaining"
            let D=NUMTRIES/2
            while [ $D -ne 0 ]; do
                echo -n "."
                let D=D-1
            done
            echo -n "  $CR"
            let NUMTRIES=NUMTRIES-1
            sleep 5
        else
            echo ""
            echo "Twissandra pod running!"
        fi
    fi
done
echo ""
if [ $NUMTRIES -le 0 ]; then
    echo "Twissandra pod did not start in alotted time...exiting"
    # clean up the potential mess
    . ./webui-down.sh --cluster $CLUSTER_LOC
    exit 3
fi
echo " "
echo "Pods:"
$kubectl_local get pods
echo " "
#
# git the user the correct URLs for opscenter and connecting that to the cluster
#
# NO ERROR CHECKING HERE...this is ALL just Informational for the user
#
SERVICEIP=`$kubectl_local get services twissandra --output=template --template="{{.portalIP}}" 2>/dev/null`
PUBLICPORT=`$kubectl_local get services twissandra --output=template --template="{{range $.spec.ports}}{{.port}}${CRLF}{{end}}" 2>/dev/null`
PUBLICIP=`$kubectl_local get services twissandra --output=template --template="{{.spec.publicIPs}}" 2>/dev/null`
# remove [] if present
PUBLICIPS=`echo $PUBLICIP | tr -d '[]' | tr , '\n'`
#
# NEED TO VALIDATE the PUBLICIPS against the NODEIPS
#
VALIDIPS=""
for ip0 in ${PUBLICIPS};do
    for ip1 in ${NODEIPS};do
        if [ "$ip0" == "$ip1" ];then
            VALIDIPS=${VALIDIPS}${CRLF}$ip0
            break
        fi
    done
done
#
# check to see that we acutally HAVE a publicly accessible IP
#
if [ -z "$VALIDIPS" ];then
    echo "======!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!=================="
    echo ""
    echo "No valid publicIPs have been defined that match a node IP.  The web UI will not be accessible."
    echo "Twissandra publicIPs:"
    echo "${PUBLICIPS}"
    echo "Node IPs:"
    echo "${NODEIPS}"
    echo ""
    echo "Please correct your twissandra-service.yaml file publicIPs: entry to include"
    echo "at least one of the Node IPs lists above"
    echo ""
    echo "Leaving demo up.  You may tear id down via ./webui-down.sh --cluster $CLUSTER_LOC"
    echo "======!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!=================="
    #exit 99
fi

echo "===================================================================="
echo " "
echo "  Twissandra Demo is Up!"
echo " "
echo "  Twissandra should be accessible via a web browser at one of "
echo "  these IP:Port(s):"
echo " "
for ip in ${VALIDIPS};do
echo "      $ip:${PUBLICPORT}"
done
echo " "
echo " Please run ./webui-down.sh --cluster $CLUSTER_LOC to stop and remove the demo when you"
echo " are finished."
echo " "
echo "===================================================================="
echo "+++++ twissandra started in Kubernetes ++++++++++++++++++++++++++++"
