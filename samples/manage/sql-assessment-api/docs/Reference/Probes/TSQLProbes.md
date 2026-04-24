# SQL probe

**Type code:** *SQL*

T-SQL probes are based on T-SQL queries used to retrieve data from the specified databases for further assessment of your environment.

## Implementation properties

Implementation part of the probe definition contains the following parameters.

| Parameter   | Required | Type   | Default | Description                       |
|-------------|:--------:|:------:|:-------:|-----------------------------------|
| query       | Required | String |         | T-SQL query                       |
| UseDatabase | Optional | Bool   | *false* | Indicates whether `USE DATABASE` statement should be issued before running the query. use for probes targeted to databases|
| timeout     | Optional | Number | 30      | Sets command execution timeout in seconds|

## Example

```json
{
    "type": "SQL",
    "target": {
        "type": "Server",
        "engineEdition": "OnPremises",
        "platform": "Linux",
        "version": "[11.0,)"
    },
    "implementation": {
        "query": "SELECT [host_platform] AS [host_platform] ,[host_release] AS [host_release] ,64 AS [host_architecture] FROM sys.dm_os_host_info(NOLOCK)",
        "transform": {
            "type": "parse",
            "map": {
                "host_release": "/^(?<major>\\d+)\\.(?<minor>\\d+)(?:\\.(?<build>\\d+))?(?:\\.(?<revision>\\d+))?$/x"
            }
        }
    }
}
```
