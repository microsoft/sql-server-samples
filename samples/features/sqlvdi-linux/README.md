# SQLVDI for Linux
This folder contains the latest files and samples required to build a SQL Server VDI based backup/restore application for Linux.

## Files available
1. vdi.h
2. vdierror.h
3. vdipipesample.cpp
4. MAKEFILE

## Known Bugs

There is a problem with VDF_LikeDisk and VDF_RandomAccess where the backup/restore is aborted unexpectedly.

## Steps

1. Install the mssql-server and mssql-tools packages 

   [Install SQL Server on Linux](http://docs.microsoft.com/sql/linux/sql-server-linux-setup) 
   [Install SQL Server tools on Linux](http://docs.microsoft.com/sql/linux/sql-server-linux-setup-tools) 
 
1. Install the clang and uuid-dev packages in order to build the sample.

   Example (for Ubuntu): 

   ```bash
   sudo apt-get install clang 
   sudo apt-get install uuid-dev 
   ```

1. Create a symbolic link to sqlcmd in /usr/bin

   ```bash
   sudo ln -s /opt/mssql-tools/bin/sqlcmd /usr/bin/sqlcmd
   ```

1. Copy the vdi sample files to a directory on your Linux machine.

1. Run make to build the sample code

1. Run the vdi client as the mssql user or follow these instructions:
	
    - Add the user running the vdi client to mssql group `sudo usermod -a -G mssql vdiuser`.
	- Add the mssql user to the vdi client user's group `sudo usermod -a -G vdiuser mssql`.
	- Reboot

1. Run the following command to issue a database backup of pubs:
	
   ```bash
   LD_LIBRARY_PATH="/opt/mssql/lib" ./vdipipesample B D pubs sa <SQLSAPASSWORD> /tmp/pubs.bak
   ```
