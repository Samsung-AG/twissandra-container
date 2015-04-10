# **tissandra-kubernetes**
##  build and tools
### Purpose
This captures the configurations etc need to run twissandra under kubernetes

### Pieces


#### Service

The twissandra web service exposes port 8222.


#### Pod

The pod looks for a Kubernetes cassandra service and attempts to connect.  
NOTE: this uses a github clone of the development twissandra repository, (vs baking the app into the image)  This could result in a slow startup.

