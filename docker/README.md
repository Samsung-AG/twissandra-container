# **tissandra-docker**
##  build and tools
### Purpose
This builds 3 docker images from twissandra

### Assumptions
* `docker` installed
* cassandra container/service is accessible via the name `cass`

### Images:
* **mikeln/twissandra_db_img** - cassandra schema creation and DB data erase if present

* **mikeln/twissandra_app_img** - twissandra app itself 
	* NOTE: exposes port 8222
	* Inject Data Is accomplished from within the web app

* **mikeln//twissandra_inj_img** - data injection tool **(DEPRECATED USE app itself)**
	* 	Args:
		* Number of new users to add
		* Number of new tweets to add
		* Delay in seconds between tweets
		* Random distribution flag
	* Description
		Normal operation creates and inserts num users * num tweets random tweet data, with a delay of n sec between each tweet insert.  If the random distribution flag is set, a distribution of tweets is created and inserted.  This is always less than users * tweets.	
	
* **mikeln/twissandra_shell_img** - invokes django with no arguments.  This will dump HELP info and exit.
    * NOTE: built by hand via make build-shell

### Building Images
You must set your Docker Image Repository before running a build.  Run `make` to receive an explanation:

    l2067532491-mn:docker$ make
    +++++++++++++++++++++++++++++++++++++++++++++++++++
      You have not changed DOCKER_REPO from: samsung_cnct
      You MUST set DOCKER_REPO in your environment
      or directly in this Makefile unless you are
      building for the group
    +++++++++++++++++++++++++++++++++++++++++++++++++++

  `export DOCKER_REPO=<yourrepo>`
  
    l2067532491-mn:docker$ export DOCKER_REPO=mikeln
    l2067532491-mn:docker$ make
    +++++++++++++++++++++++++++++++++++++++++++++++++++
      Your DOCKER_REPO is set to: mikeln
      Please execute 'make all' to build
    +++++++++++++++++++++++++++++++++++++++++++++++++++

The Makefile will create the images:
  
  `make all`
  
To clean the local image cache and build:

   `make clean`

NOTE: The Makefile assumes that docker is installed.

NOTE: The Dockerfile is created for each image from the appropriate Dockerfile.<blah> file.
	
### Recommended Invocations

Example of cassandra running in a `docker` container as name `cass1`.

This information is captured in `run.sh`:

`docker run -it --rm --name twiss_init --link cass1:cass mikeln/twissandra_db_img`

`docker run --rm --name twis_app -p 8222:8222 --link cass1:cass twissandra_app_img
`


