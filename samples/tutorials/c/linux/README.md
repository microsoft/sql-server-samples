# Connect to MSSQL using the Microsoft ODBC Driver on Linux


[C code sample](sample_c_linux.c) that runs on Linux. The sample connects to MSSQL (SQL Server, Azure SQL DB, Azure SQL DW) using the Microsoft ODBC Driver for Linux.


## Prerequisites


Open your terminal and install the Microsoft ODBC Driver on your machine

Install the ODBC Driver for Linux on Ubuntu 15.10:

	sudo su
	sudo sh -c 'echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/mssql-ubuntu-preview/ wily main" > /etc/apt/sources.list.d/mssqlpreview.list'
	sudo apt-key adv --keyserver apt-mo.trafficmanager.net --recv-keys 417A0893
	sudo apt-get update
	sudo apt-get install msodbcsql
	sudo apt-get install unixodbc-dev-utf16 (this step is optional but recommended)
	
Install the ODBC Driver for Linux on Ubuntu 16.04

	sudo su
	sudo sh -c 'echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/mssql-ubuntu-preview/ xenial main" > /etc/apt/sources.list.d/mssqlpreview.list'
	sudo apt-key adv --keyserver apt-mo.trafficmanager.net --recv-keys 417A0893
	sudo apt-get update
	sudo apt-get install msodbcsql
	sudo apt-get install unixodbc-dev-utf16 (this step is optional but recommended)

Install the ODBC Driver for Linux on RedHat 6
	
	sudo su
	yum-config-manager --add-repo https://apt-mo.trafficmanager.net/yumrepos/mssql-rhel6-preview/
	yum-config-manager --enable mssql-rhel6-preview
	wget "http://aka.ms/msodbcrhelpublickey/dpgswdist.v1.asc"
	rpm --import dpgswdist.v1.asc
	yum remove unixodbc (to avoid conflicts during installation)
	yum update
	yum install msodbcsql
	yum install unixODBC-utf16-devel (this step is optional but recommended)

Install the ODBC Driver for Linux on RedHat 7

	sudo su
	yum-config-manager --add-repo https://apt-mo.trafficmanager.net/yumrepos/mssql-rhel7-preview/
	yum-config-manager --enable mssql-rhel7-preview
	wget "http://aka.ms/msodbcrhelpublickey/dpgswdist.v1.asc"
	rpm --import dpgswdist.v1.asc
	yum remove unixodbc (to avoid conflicts during installation)
	yum update
	yum install msodbcsql
	yum install unixODBC-utf16-devel (this step is optional but recommended)


After your machine is configured with the ODBC Driver change the credentials in the C sample, compile it and then run it:

	gcc sample_c_linux.c -o sample_c_linux -lodbc -w
	./sample_c_linux


