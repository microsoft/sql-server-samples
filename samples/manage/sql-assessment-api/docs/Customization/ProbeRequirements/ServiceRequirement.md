# Service requirement

Lists SQL Server services required for the probe.

## Name format

__service__

## Supported values

**MSSQL** – SQL Server service

**SQLAgent** – [SQL Server Agent service](https://learn.microsoft.com/sql/ssms/agent)

**MSOLAP** – [SQL Server Analysis Services](https://learn.microsoft.com/analysis-services)

**ReportServer** – [SQL Server Reporting Services](https://learn.microsoft.com/sql/reporting-services)

**MsDtsServer** – [Integration Services](https://learn.microsoft.com/sql/integration-services)

**MSSQLFDLauncher** – [Full-Text Filter daemon host launcher service](https://learn.microsoft.com/sql/tools/configuration-manager/sql-full-text-filter-daemon-launcher-sql-server-configuration-manager)

**SQLBrowser** – [SQL Server Browser service](https://learn.microsoft.com/sql/tools/configuration-manager/sql-server-browser-service)

## Examples

```json
"runFor": {
    "service": [ "ReportServer" ]
}
```

## See also

- [attr::service:: variables](../AutomaticVariables/AttrService.md)
- [Probe requirements](./README.md)

