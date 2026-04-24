# Disabling Built-in Rules

You can silence specific rules when they aren't applied to your environment or until the scheduled work is done to rectify the issue.

The following is an example consisting of three rules. The first rule shows how to disable the check by specifying its ID, the second example disables all checks that have the **TraceFlag** tag, and the third example disables all checks from the default ruleset using the **DefaultRuleset** tag for databases **DBName1** and **DBName2**.

```json
{
    "schemaVersion": "1.0",
    "version": "0.2",
    "name": "Custom Overrides",
    "rules":
    [
        {
            "id": "LatestCU",
            "itemType": "override",
            "enabled": false
        },
        {
            "id": ["TraceFlag"],
            "itemType": "override",
            "enabled": false
        },
        {
            "id": ["DefaultRuleset"],
            "itemType": "override",
            "targetFilter":
            {
                "type": "Database",
                "name": [ "DBName1", "DBName2" ]
            },
            "enabled": false
        }
    ]
}
```