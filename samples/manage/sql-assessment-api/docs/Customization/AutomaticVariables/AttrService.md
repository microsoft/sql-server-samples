# attr::service:: variables

[Automatic variables](./README.md) in the **attr::service::* namespace are provided with [Service requirements](../ProbeRequirements/ServiceRequirement.md).

The following variables are available for each service. Service key is  a value from [Service requirement supported values](../ProbeRequirements/ServiceRequirement.md#supported-values).

| Variable name                | Type   | Description                          |
|------------------------------|--------|--------------------------------------|
| attr::service::_key_         | bool   | Inidicates if the service is present |
| attr::service::_key_.name    | string | Actual service name                  |
| attr::service::_key_.account | string | User account name for this service   |

## Examples

In the following example the message will report actual user account name when the SQL Server Agent service is present and running under local service account. See [Message template](../MessageTemplate.md).

```json
{
    …
    "message": "Account '@{attr::service::SQLAgent.account}' is not supported for 'SQL Server Agent' service.",
    "localServiceAccount": "NT AUTHORITY\\LOCALSERVICE",
    "condition": [
        { "not": "@attr::service::SQLAgent" },
        { "ine": [
            "@attr::service::SQLAgent.account",
            "@localServiceAccount"
        ]}
    ],
    "probes": [ "IsClusteredServer" ]
}
```

The next example extends the previous check with support for clustered servers. When the server is clustered, three more accounts are not supported.

```json
{
    …
    "message": "Account '@{attr::service::SQLAgent.account}' is not supported for 'SQL Server Agent' service.",
    "localServiceAccount": "NT AUTHORITY\\LOCALSERVICE",
    "unsupportedAccounts": [
        "NT AUTHORITY\\SYSTEM",
        "LOCALSYSTEM",
        "NT AUTHORITY\\NETWORKSERVICE"
    ],
    "condition": [
        { "not": "@attr::service::SQLAgent" },
        {
            "ine": [
                "@attr::service::SQLAgent.account",
                "@localServiceAccount"
            ],
            "or": [
                { "not": "@is_clustered_server" },
                { "not": {
                    "iin": [
                        "@attr::service::SQLAgent.account",
                        "@unsupportedAccounts"
                    ]
                }}
            ]
        }
    ],
    "probes": [ "IsClusteredServer" ]
}
```
