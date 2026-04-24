# Wait for SQL Server to start and be ready to accept connections
sleep 35s
echo sa_password is $SA_PASSWORD
/opt/mssql-tools/bin/sqlcmd -S . -U sa -P $SA_PASSWORD -i /tmp/backup/restore.sql
 