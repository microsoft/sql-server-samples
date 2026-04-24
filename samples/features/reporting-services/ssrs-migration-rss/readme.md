# SQL Server Reporting Services migration script

This is a Microsoft SQL Server Reporting Services RSS script that migrates content from one Reporting Services server to another.

Run the script with the rs.exe utility.  Rs.exe is installed by Reporting Services.

For details about rs.exe see: https://docs.microsoft.com/sql/reporting-services/tools/rs-exe-utility-ssrs

For more detailed instructions and examples of using the script, see: https://docs.microsoft.com/sql/reporting-services/tools/sample-reporting-services-rs-exe-script-to-copy-content-between-report-servers

The script supports report server versions SQL Server 2008 R2 and later and Power BI Report Server, and both native mode report servers and SharePoint mode report servers. It can be run from the source or target server.

## To use the script

1) Download ssrs_migration.rss

2) Open a command prompt and navigate to the folder containing ssrs_migration.rss, for example c:\rss

3) Run the command in the rss file in one line.

## Limitations

- Passwords are not migrated, and must be re-entered (e.g. data sources with stored credentials)

## Additional info

The virtual folder structure presented to the user in SharePoint might be different
from the physical structure that is used by this script.

Open http://servername/_vti_bin/reportserver in a browser to see the non-virtual folder structure.

This is helpful for setting SrcFolder and SnkFolder to something other than "/" for a server in SharePoint integrated mode.


