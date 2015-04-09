#/bin/bash
#
# DEPRECATED... original run setup... ONLY HERE FOR REFERENCE 4/9/2015 MLN
#
# INCORRECT, but gives a hint how to run cass and twiss by hand
#
#docker run -it --rm --name twiss_init --link cass1:cass mikeln/twissandra_db_img
#docker run --rm --name twiss_inj --link cass1:cass mikeln/twissandra_inj_img 10 10 0 0
#docker run --rm --name twis_app -p 8000:8000 --link cass1:cass mikeln/twissandra_app_img

#docker run -d -p 9160:9160 -p 9042:9042 --name cass1 zmarcantel/cassandra
#docker run -it --rm --link cass1:cass zmarcantel/cassandra cqlsh cass
