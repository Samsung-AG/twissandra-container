#!/bin/bash  
#
# Script to start all the pieces of the twissandra benchmark
# requires a cassandra cluster running as a kubernetes service
#
# 4/22/2015 mikeln
#-------
# some best practice stuff
CRLF=$'\n'
CR=$'\r'
unset CDPATH
#
echo " "
echo "=================================================="
echo "   Attempting to Start the"
echo "   Twissandra Kubernetes Demo"
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
echo "  You must have a cassandra cluster running and"
echo "  the cassandra-service advertised"
echo "=================================================="
#
# setup trap for script signals
#
trap "echo ' ';echo ' ';echo 'SIGNAL CAUGHT, SCRIPT TERMINATING, cleaning up'; . ./benchmark-down.sh; exit 9 " SIGHUP SIGINT SIGTERM
#----------------------
# start the services first...this is so the ENV vars are available to the pods
#----------------------
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
KUBECONFIG=`find ${KRAKENDIR} -type f -name ".kubeconfig" -print | egrep 'kubernetes'`
if [ $? -ne 0 ];then
    echo "Could not find Kraken .kubeconfig"
else
    echo "found: $KUBECONFIG"
fi

KUBECTL=`find /opt/kubernetes/platforms/darwin/amd64 -type f -name "kubectl" -print | egrep '.*'`
if [ $? -ne 0 ];then
    echo "Could not find kubectl."
    exit 1
else
    echo "found: $KUBECTL"
fi

#kubectl_local="/opt/kubernetes/platforms/darwin/amd64/kubectl --kubeconfig=/Users/mikel_nelson/dev/cloud/kraken/kubernetes/.kubeconfig"
kubectl_local="${KUBECTL} --kubeconfig=${KUBECONFIG}"

CMDTEST=`$kubectl_local version`   
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running? (Hint: vagrant status, vagrant up)"
    exit 1;
else
    echo "kubectl present: $kubectl_local"
fi
echo " "
# get minion IPs for later...also checks if cluster is up
echo "+++++ finding Kubernetes Nodes services ++++++++++++++++++++++++++++"
NODEIPS=`$kubectl_local get nodes --output=template --template="{{range $.items}}{{.metadata.name}}${CRLF}{{end}}" 2>/dev/null`
if [ $? -ne 0 ]; then
    echo "kubectl is not responding. Is your Kraken Kubernetes Cluster Up and Running? (Hint: vagrant status, vagrant up)"
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
echo "Services List:"
$kubectl_local get services
echo " "
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
$kubectl_local create -f kubernetes/dataschema.yaml 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Twissandra dataschema pod error"
    . ./benchmark-down.sh
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
    . ./benchmark-down.sh
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
$kubectl_local create -f kubernetes/benchmark.yaml 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Twissandra benchmark pod error"
    . ./benchmark-down.sh
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
    LASTSTATUS=`$kubectl_local get pods benchmark --output=template --template={{.status.phase}} 2>/dev/null`
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
    . ./benchmark-down.sh
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
