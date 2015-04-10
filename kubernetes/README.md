# **twissandra-kubernetes**
##  build and tools
### Purpose
This captures the configurations etc need to run twissandra under kubernetes

### Pieces


#### Service

The twissandra web service exposes port 8222.


#### Pod

The pod looks for a Kubernetes cassandra service and attempts to connect.  
NOTE: this uses a github clone of the development twissandra repository, (vs baking the app into the image)  This could result in a slow startup.

#### Demo Script

* Make sure the Kubernetes cassandra service is running and there is at least one cassandra pod running.
* It this is the first time running on a new DB cluster, you must create the schema first. (Or, if you want to erase ALL the data in the DB): 
	* `kubectl create -f dataschema.yaml`
	* Wait until this finishes.  This is a one-shot pod.  You have to delete it by hand after it is done.
	* `kubectl delete -f dataschema.yaml`
 * Start the twissandra server:
 	* `kubectl create -f twissadra-service.yaml`
 	* This will start the service on port 8222
 * Run the twissandra POD:
 	* `kubectl create -f twissandra.yaml`
 	* Any problems can be diagnosed on the minion, via sudo docker logs <>
 	* Normally, the issue will be missing schema, in which case you need to do the step above.
 * Connect a Web Browser to twissandra
 	* `http://172.16.1.103:8222`
 	* NOTE: the IP is whatever minion is running the twissandra pod
 * Use the Inject_data link/page to inject #user * #tweets records.
 
 	
 	
 
     

