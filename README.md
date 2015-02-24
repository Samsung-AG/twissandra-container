# **tissandra-docker**
##  build and tools
### Purpose
This builds 3 docker images from twissandra

### Images:
* **mikeln/twissandra_db_img** - cassandra schema creation or DB data erase
* **mikeln//twissandra_inj_img** - data injection tool
	* 	Args:
		* Number of new users to add
		* Number of new tweets to add
		* Delay in seconds between tweets
		* Random distribution flag
	* Description
		Normal operation creates and inserts num users * num tweets random tweet data, with a delay of n sec between each tweet insert.  If the random distribution flag is set, a distribution of tweets is created and inserted.  This is always less than users * tweets.
* **mikeln/twissandra_app_img** - twissandra app itself 
	* NOTE: exposes port 8000
	* NOTE: currently does not work correctly
	
### Building Images
The Makefile will create the images:
  
  `make all`
  
To clean the local image cache and build:

   `make clean`

NOTE: The Makefile assumes that docker is installed.

NOTE: The Dockerfile is created for each image from the appropriate Dockerfile.<blah> file.
	
### Recommended Invocations
This information is captured in run.sh:

`docker run -it --rm --name twiss_init --link cass1:cass mikeln/twissandra_db_img`

`docker run --rm --name twiss_inj --link cass1:cass mikeln/twissandra_inj_img 10 10 0 0`

`docker run --rm --name twis_app -p 8000:8000 --link cass1:cass twissandra_app_img
`


