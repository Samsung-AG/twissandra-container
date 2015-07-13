# **tissandra-container**
##  build and tools
### Purpose
This builds containers (docker and kubernetes) 

See subdirectory README.md for specific instructions.

## Benchmark
The benchmark creates the Twissandra schema in a connected Cassandra DB cluster, then starts the Twissandra Django server.  Fixed data is then injected into the cassandra cluster.

The twissandra benchmark command takes 2 arguments: number of new users and number of tweets for each user.  Each user name is a fixed size of 10 random characters.  Each tweet is a fixed size of 80 random characters.  The result is #user * #tweets new data records.  There is also another join type table that is updated.

### Scripts
Several bash scripts have been created to automate the creation and timing of the benchmark.  They automate the sequence documented below.  Note that these scripts assume you are running on a Kraken CoreOS cluster using those IPs and names, and that you have a running Cassandra cluster.

There are 4 scripts: ````benchmark-run.sh```` and ````benchmark-down.sh````, ````benchmark-04-run.sh```` and ````benchmark-04-down.sh````

#### ````benchmark-run.sh```` 
* Usage

````
        Usage:
           benchmark-run.sh [flags]

        Flags:
             -n, --noschema :: Flag to avoid running the schema creation step
             -c, --cluster : local : [local, aws, ???] selects the cluster yaml/json to use
             -h, -?, --help :: print usage
             -v, --version :: print script verion 
````

* Locates the Kubectl needed for Kraken
* Uses ~/.kube/config. Requires an entry exists for the desired cluster. Example for local:

````
        apiVersion: v1
        clusters:
        - cluster:
            api-version: v1
            server: http://172.16.1.102:8080
          name: local
        contexts: []
        current-context: ""
        kind: Config
        preferences: {}
        users: []

````

* Uses the information to construct the correct ````kubectl```` command.  e.g.:

````
        kubectl='/opt/kubernetes/platforms/darwin/amd64/kubectl --cluster=local'
````

* Checks that the Cassandra service is running
* Runs the Twissandra dataschema creation Pod
* Waits until the dataschema Succeeds (up to 10 minutes)
* Checks for any previous benchmark pods and deletes them if present.
* Starts the benchmark pod
* Starts a timer when the pod goes to "Running"
* Monitors for "Succeeded" or "Failed" and calculates the elapsed time in seconds.
* Control-C at any point will terminate and tear down the entire setup (via ````benchmark-down.sh````)
* Any error will terminate and tear down the entire setup (via ````benchmark-down.sh````)

#### ````benchmark-down.sh````
* Usage

````
        Usage:
           benchmakr-down.sh [flags]

        Flags:
             -c, --cluster : local : [local, aws, ???] selects the cluster yaml/json to use
             -h, -?, --help :: print usage
             -v, --version :: print script verion
````

* Locates the Kubectl needed for Kraken
* Locates the .kubeconfig in the kraken/kubernetes directory
* Uses the information to construct the correct ````kubectl```` command.  e.g.:

````
        kubectl='/opt/kubernetes/platforms/darwin/amd64/kubectl --cluster=local'
````

* Removes the Datachema (if present) and Benchmark Pods


#### ````benchmark-04-run.sh```` 
* The same as ````benchmark-run.sh```` but runs 4 pods named benchmark-01 to benchmark-04
* Times from when the first pod status is "Running" until all 4 are "Succeeded".
* Any "Failed" will abort the whole thing

#### ````benchmark-04-down.sh````
* The same as ````benchmark-down.sh```` except removes all 4 pods via label selector.

## Demo
The demo creates the Twissandra schema in a connected Cassandra DB cluster, then starts the Twissandra Django web server.  Random data injection can be commanded from the web UI.

### Scripts
Several bash scripts have been created to automate the creation of the demo.  They automate the sequence documented below.  Note that these scripts assume you are running on a Kraken CoreOS cluster using those IPs and names, and that you have a running Cassandra cluster.

There are 2 scripts: ````webui-run.sh```` and ````webui-down.sh````.  

#### ````webui-run.sh```` 
* Usage

````
        Usage:
           webui-run.sh [flags]

        Flags:
             -n, --noschema :: Flag to avoid running the schema creation step
             -c, --cluster : local : [local, aws, ???] selects the cluster yaml/json to use
             -h, -?, --help :: print usage
             -v, --version :: print script verion 
````

* Locates the Kubectl needed for Kraken
* Uses ~/.kube/config. Requires an entry exists for the desired cluster. Example for local:

````
        apiVersion: v1
        clusters:
        - cluster:
            api-version: v1
            server: http://172.16.1.102:8080
          name: local
        contexts: []
        current-context: ""
        kind: Config
        preferences: {}
        users: []

````

* Uses the information to construct the correct ````kubectl```` command.  e.g.:

````
        kubectl='/opt/kubernetes/platforms/darwin/amd64/kubectl --cluster=local'
````

* Checks that the Cassandra service is running
* Runs the Twissandra dataschema creation Pod
* Waits until the dataschema Succeeds (up to 10 minutes)
* Runs the Twissandra web server Pod 
* Waits until Twissandra is running (up to 10 minutes)
* Locates the IPs and Ports and provides information to about the connections
* Control-C at any point will terminate and tear down the entire setup (via ````demo-down.sh````)
* Any error will terminate and tear down the entire setup (via ````demo-down.sh````)

#### ````webui-down.sh````
* Locates the Kubectl needed for Kraken
* Usage

````
        Usage:
           webui-down.sh [flags]

        Flags:
             -c, --cluster : local : [local, aws, ???] selects the cluster yaml/json to use
             -h, -?, --help :: print usage
             -v, --version :: print script verion
````

* Uses ~/.kube/config. Requires an entry exists for the desired cluster. Example for local:

````
        apiVersion: v1
        clusters:
        - cluster:
            api-version: v1
            server: http://172.16.1.102:8080
          name: local
        contexts: []
        current-context: ""
        kind: Config
        preferences: {}
        users: []

````

* Uses the information to construct the correct ````kubectl```` command.  e.g.:

      kubectl='/opt/kubernetes/platforms/darwin/amd64/kubectl --cluster=local'

* Removes all services
* Removes the Datachema (if present) and Twissandra Pods

#### Example Run

    2067532491-mn:twissandra-container mikel_nelson$ ./demo-run.sh

    ==================================================
       Attempting to Start the
       Twissandra Kubernetes Demo
    ==================================================
      !!! NOTE  !!!
      This script uses our kraken project assumptions:
         kubectl will be located at (for OS-X):
           /opt/kubernetes/platforms/darwin/amd64/kubectl
        .kubeconfig is from our kraken project

      Your Kraken Kubernetes Cluster Must be
      up and Running.

      You must have a cassandra cluster running and
      the cassandra-service advertised
    ==================================================

    Locating Kraken Project kubectl and .kubeconfig...
    DEVBASE /Users/mikel_nelson/dev/cloud
    found: /Users/mikel_nelson/dev/cloud/kraken
    found: /Users/mikel_nelson/dev/cloud/kraken/kubernetes/.kubeconfig
    found: /opt/kubernetes/platforms/darwin/amd64/kubectl
    kubectl present: /opt/kubernetes/platforms/darwin/amd64/kubectl --cluster=local

    +++++ finding Kubernetes Nodes services ++++++++++++++++++++++++++++
    Kubernetes minions (nodes) IP(s):
       172.16.1.103
       172.16.1.104

    +++++ checking for cassandra services ++++++++++++++++++++++++++++
    NAME        LABELS    SELECTOR         IP               PORT
    cassandra   <none>    name=cassandra   10.100.143.116   9042
    Found Cassandra service.

    services/twissandra
    Twissandra service started
    NAME         LABELS    SELECTOR          IP               PORT
    twissandra   <none>    name=twissandra   10.100.115.234   8222
    Twissandra service found
    Services List:
    NAME                  LABELS                                    SELECTOR          IP               PORT
    cassandra             <none>                                    name=cassandra    10.100.143.116   9042
    cassandra-opscenter   <none>                                    name=opscenter    10.100.168.78    8888
    kubernetes            component=apiserver,provider=kubernetes   <none>            10.100.0.2       443
    kubernetes-ro         component=apiserver,provider=kubernetes   <none>            10.100.0.1       80
    twissandra            <none>                                    name=twissandra   10.100.115.234   8222

    +++++ Creating Needed Twissandra Schema ++++++++++++++++++++++++++++
    pods/dataschema
    Twissandra dataschema pod started
    Twissandra datachema pod: Running - NOT Succeeded 575 secs remaining.........................................................
    Twissandra datachema pod finished!

    pods/dataschema

    +++++ starting Twissandra pod ++++++++++++++++++++++++++++
    pods/twissandra
    Twissandra pod started

    Pods:
    POD               IP            CONTAINER(S)   IMAGE(S)                      HOST                        LABELS            STATUS    CREATED
    cassandra-idqk2   10.244.20.3   cassandra      mikeln/cassandra_kub_mln:v9   172.16.1.103/172.16.1.103   name=cassandra    Running   2 hours
    cassandra-ztg06   10.244.28.3   cassandra      mikeln/cassandra_kub_mln:v9   172.16.1.104/172.16.1.104   name=cassandra    Running   2 hours
    opscenter         10.244.28.4   opscenter      mikeln/opscenter-kub-mln:v1   172.16.1.104/172.16.1.104   name=opscenter    Running   2 hours
    twissandra                      twissandra     mikeln/twissandra_img:v7      172.16.1.103/               name=twissandra   Pending   Less than a second

    Waiting for all needed pods to indicate Running

    Twissandra pod: Waiting - NOT running 600 secs remaining............................................................
    Twissandra pod running!


    Pods:
    POD               IP             CONTAINER(S)   IMAGE(S)                      HOST                        LABELS            STATUS    CREATED
    cassandra-idqk2   10.244.20.3    cassandra      mikeln/cassandra_kub_mln:v9   172.16.1.103/172.16.1.103   name=cassandra    Running   2 hours
    cassandra-ztg06   10.244.28.3    cassandra      mikeln/cassandra_kub_mln:v9   172.16.1.104/172.16.1.104   name=cassandra    Running   2 hours
    opscenter         10.244.28.4    opscenter      mikeln/opscenter-kub-mln:v1   172.16.1.104/172.16.1.104   name=opscenter    Running   2 hours
    twissandra        10.244.20.12   twissandra     mikeln/twissandra_img:v7      172.16.1.103/172.16.1.103   name=twissandra   Running   5 seconds

    ====================================================================

      Twissandra Demo is Up!

      Twissandra should be accessible via a web browser at one of
      these IP:Port(s):

          172.16.1.103:8222
          172.16.1.104:8222

     Please run ./demo-down.sh to stop and remove the demo when you
     are finished.

    ====================================================================
    +++++ twissandra started in Kubernetes ++++++++++++++++++++++++++++
    
