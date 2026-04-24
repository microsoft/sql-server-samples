# SqlServerOnDocker
Prof of concept project with Microsoft SQL Server and Django Framework setup on docker containers.

## To start development:
1. install [docker](https://docs.docker.com/#/components) and [docker-compose](https://docs.docker.com/compose/install/)
2. clone this repository
3. run `docker-compose build db` to build db container
4. run `docker-compose up -d db` to run SQL Server container in detached mode in the background
5. run `docker-compose run db sqlcmd -S db1.internal.prod.example.com -U SA -P 'Alaska2017' -Q  "RESTORE FILELISTONLY FROM DISK = N'/var/opt/mssql/backup/AdventureWorksDW2017.bak'"`
    to verify database file names before restore,
6. run `docker-compose run db sqlcmd -S db1.internal.prod.example.com -U SA -P 'Alaska2017' -Q  "RESTORE DATABASE AdventureWorksDW2017 FROM DISK = N'/var/opt/mssql/backup/AdventureWorksDW2017.bak' WITH MOVE 'AdventureWorksDW2017' TO '/var/opt/mssql/data/AdventureWorksDW2017.mdf', MOVE 'AdventureWorksDW2017_log' TO '/var/opt/mssql/data/AdventureWorksDW2017_log.ldf' "`
    to restore AdventureWorksDW2017 database on SQL Server
7. run `docker-compose run web python3 manage.py migrate` to apply migrations on default database. In this case it will be AdventureWorksDW2017.
8. run `docker-compose run web python3 manage.py createsuperuser` to create admin account

## To run project:

1. run `docker-compose up web`
2. point your browser to `localhost:8080`
3. press `CTRL+C` to stop

## Access to sql server
1. sudo docker-compose run db sqlcmd -S db1.internal.prod.example.com -U SA -P 'Alaska2017' -Q 'select 1 from AdventureWorksDW2017'
2. sudo docker exec -it sqlserverondocker_db_1 bash
