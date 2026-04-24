# Probe requirements

Probe requirements help to deal with situations when a probe cannot get data due to insufficient permissions or configuration issues. SQL Assessment API can skip probes when their requirements were stated explicitly.

By default any error in probe terminates assessment process immediately with an error message. This leads to incomplete results because not all checks have been run. For example, the following probe will generate an error and terminate assessment if current user does not have _sysadmin_ role.

```json
"DBMetaInfo": [
    {
        "type": "SQL",
        "target": { "type": "Database" },
        "implementation": {
          "query": "DBCC DBINFO(@TargetName) WITH TABLERESULTS,NO_INFOMSGS",
        }
    }
]
```

This requirement can be specified explicitly in the probe's __requires__ property. With this property SQL Assessment API will check if current user has _sysadmin_ role before running the query. If not, the query will not be run and all checks, that depend on this probe, will be skipped. The user will get a warning about this.

```json
"DBMetaInfo": [
    {
        "type": "SQL",
        "target": { "type": "Database" },
        "implementation": {
          "query": "DBCC DBINFO(@TargetName) WITH TABLERESULTS,NO_INFOMSGS",
        },
        "requires": {
          "role": [ "sysadmin" ]
        }
    }
]
```

In some scenarios there is no need for the warning. Let's take a probe which detects database mirroring endpoints with the following T-SQL query.

```sql
SELECT
    [name] AS endpoint_name,
    is_encryption_enabled,
    encryption_algorithm,
    encryption_algorithm_desc
FROM
    sys.database_mirroring_endpoints
```

This probe makes little sense when High Availability abd Disaster Recovery (HADR) is disabled. We can add a requirement for this probe to skip it in these cases.

```json
"AGEndpoints": [
    {
        "type": "SQL",
        "target": { "type": "Server" },
        "implementation": { "query": " … " },
        "requires": {
          "feature": [ "HADR" ]
        }
    }
]
```

With this implementation, the user will get a warning for each SQL Server instance not involved in HADR operations, which would be confusing. There is another probe propery named __runFor__ which specifies requirements in the same format as __requires__. The difference is the absence of the warning message. The probe does not run the query but return an empty set immediately.

```json
"AGEndpoints": [
    {
        "type": "SQL",
        "target": { "type": "Server" },
        "implementation": { "query": " … " },
        "runFor": {
          "feature": [ "HADR" ]
        }
    }
]
```

Each requirement is represented by a JSON property. The property name is the requirement name. The property value is a JSON array of strings representing required values. For example, the following probe requires _ALTER TABLE_ and _ADMINISTER BULK OPERATIONS_ server permissions.

```json
"requires": {
    "server permission": [
        "ALTER TABLE",
        "ADMINISTER BULK OPERATIONS"
    ]
}
```

## Requirement types

SQL Assessment API supports a variety of requirement types. The are documented below.

Each requirement type has specific name format. Fixed literal characters in the name format are __bold__. Variable parts of the name are _italic_. Optional parts are __\[__ enclosed in square brackets __\]__.

Supported requirement types:

- [role](./RoleRequirement.md)
- [permission](./PermissionRequirement.md)
- [feature](./FeatureRequirement.md)
- [service](./ServiceRequirement.md)
