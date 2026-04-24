#start SQL Server, start the script to create/setup the DB
#You need a non-terminating process to keep the container alive.
#In a series of commands separated by single ampersands the commands to the left of the right-most ampersand are run in the background.
#So - if you are executing a series of commands simultaneously using single ampersands, the command at the right-most position needs to be non-terminating
 /db-init.sh & /opt/mssql/bin/sqlservr
 