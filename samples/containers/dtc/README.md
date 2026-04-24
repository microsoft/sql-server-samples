## SQL Server Replication with Containers

This demo uses docker-compose to start two SQL Server containers; one that acts as the publisher and distributor, and the other as the subscriber in a push snapshot configuration.


### How to Use

1. Run the following command in this directory:

```
docker-compose up
```
note: this will take approx. 2 min.

In your terminal, you should see something like this
```
db1    | Job 'DB1-Sales-SnapshotRepl-1' started successfully.
db1    | Creating Snapshot...
db1    | Job 'db1-Sales-SnapshotRepl-DB2-1' started successfully.
```

2. Connect to the subscriber listening on localhost,2600 and see that the Sales Database has a Customer table with data in it.
note: credentials are listed in the **docker-compose.yml**

3. when you are done, clean up by running the following command
```
docker-compose down
```



### How it Works

1. Both SQL Server containers start with the environment variables specified in the docker-compose file. In this example, **db1** is the publisher/distributor and **db2** is the subscriber.
2. *db1/db-init.sh* and *db2/db-init.sh* waits for SQL Server to start up and run the *db-init.sql* scripts
3. *db1/db-init.sql* creates a *Sales* Database with *Customer* table and sample data, and proceeds by setting up snapshot replication.
4. *db2/db-init.sql* creates a *Sales* Database.
5. db1 starts replication jobs to push the snapshot to db2