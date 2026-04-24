# Permission requirement

Permission requirements specify special permissions required by the probe. for more information see [sys.fn_my_permissions](https://learn.microsoft.com/sql/relational-databases/system-functions/sys-fn-my-permissions-transact-sql)

## Name format

*securable_class* __permission__ __\[__ __on__ *securable_name* __]__

*securable_class* is the name of the class of securable for which permissions are listed. *securable_class* is a sysname. Examples of *securable_class* are: DATABASE, OBJECT, REMOTE SERVICE BINDING, SERVER.

*securable_name* is the name of the securable. If the securable is the server or a database, this part should be omitted. *securable_name* is a sysname. *securable_name* can be a multipart name.

## Supported values

Allowed values depend on securable class. See [SQL Server Permissions](https://learn.microsoft.com/sql/relational-databases/security/permissions-database-engine) and [SQL Server Permissions Hierarchy](https://learn.microsoft.com/sql/relational-databases/security/permissions-hierarchy-database-engine).

## Examples

```json
"requires": {
    "server permission": [
        "ALTER TRACE"
    ]
},
```

```json
"requires": {
    "object permission on [msdb].[dbo].[sysalerts]": [
        "SELECT"
    ]
},
```

```json
"requires": {
    "object permission on [msdb].[dbo].[sysjobs]": [
        "SELECT"
    ],
    "object permission on [msdb].[dbo].[sysjobsteps]": [
        "SELECT"
    ]
},
```

## See also

- [Probe requirements](./README.md)
