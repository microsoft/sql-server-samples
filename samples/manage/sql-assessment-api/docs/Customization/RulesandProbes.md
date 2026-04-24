# Understanding rules and probes

The SQL Assessment API uses sets of best practice recommendations to check if a SQL Server environment or configuration could be improved. Best practices are not universal. Guidelines depend on SQL Server version, edition, and configuration, hosting platform, and even usage pattern. For example, some best practices are applicable only to cloud environments, whereas others work for SQL Server instances installed on a physical machine. Databases may also be of different types. For example, a set of best practices for the `msdb` database might be different from that used for user databases.

SQL Assessment API makes recommendations more specific by implementing a two-step process:

1. Build a checklist for the given target

    Such a checklist contains a complete set of checks, depending on the specified target.

2. Go through the checklist and report every best practice violation

    At this step, the SQL Assessment API goes through the checklist to validate whether the given target satisfies the given best practice.

The checklist construction process is based on rules. Each rule either defines a new check or modifies one or more of the existing ones. Rules are stored in rulesets. Each ruleset has its own name and version. Users can add multiple rulesets to the SQL Assessment API engine one by one. While building the checklist, the engine will apply rules in the order they were added.

A single check can be affected by multiple rules. The first rule must define the check and assign a unique string ID. Checks may have tags that allow managing them in groups. The following rules override checks referred by IDs or tags, which gives the override the ability to modify multiple checks at once.

For example, the following rule makes a check with the `MaxMemory` ID appear in the checklist for all SQL Server 2012 instances and higher. Note that the rule sets the `limit` parameter to 2147483647.

```json
{
    "id": "MaxMemory",
    "itemType": "definition",
    "target":
    {
        "type": "Server",
        "version": "[11.0,)"
    },
    "limit": 2147483647
}
```

The rule below modifies the limit parameter for the `MaxMemory` check defined above.

```json
{
    "id": "MaxMemory",
    "itemType": "override",
    "limit": 2000000000
}
```

Note that the rule override can modify checks for selected targets if needed. The following rules modify the limit of the `MaxMemory` check for specific SQL Server editions.

```json
{
    "id": "MaxMemory",
    "itemType": "override",
    "targetFilter":
    {
        "engineEdition": "Standard"
    },
    "limit": 131072
},

{
    "id": "MaxMemory",
    "itemType": "override",
    "targetFilter":
    {
        "engineEdition": "Express"
    },
    "limit": 1410
}
```

Having a check in the checklist does not mean this check will be run by the assessment engine. Each check has the `enabled` property which is set to *true* by default. If the property becomes false after all rules are applied, the engine will skip the check.

The following rule disables the `MaxMemory` check and all performance-related checks for all instances running on Linux.

```json
{
    "id": [ "MaxMemory", "Performance" ],
    "itemType": "override",
    "targetFilter": {
        "platform": "Linux"
    },
    "enabled": false
}
```

Each check needs data to analyze. Checks do not retrieve any data from the target server or database but refer to *probes* instead. Most of the probes use T-SQL queries, but the SQL Assessment API also supports probes for WMI, Windows registry, Azure Instance Metadata Service, as well as custom probes implemented as .NET classes.

Each probe returns zero or more data rows containing named items. If a check gets data from multiple probes, the resulting data set is constructed as *all* combinations of rows. This behavior is similar to `CROSS JOIN` in T-SQL.

A check has a condition expression which formally describes best practice as an arithmetic expression referring to data from a data row. Condition is calculated and checked if it holds for each row separately. For example, when a database uses 3 disks for storing its files, then a free space best practice may apply to each disk independently. If a check uses data from two probes, and one probe produces 2 rows while another one produces 3, the check condition will be evaluated 2×3=6 times. If condition gives *false* 2 times out of 6, the check will produce 2 messages.

At the same time, probe implementation may depend on the SQL Server version. For example, dynamic management views may vary between  SQL Server releases. This is why a probe may have multiple implementations. Each implementation has a target specification, the same way the rules do. The assessment engine uses  the most appropriate implementation for each target.

## Related topics

- [Probes](../Reference/Probes/README.md)
- [Tutorials](../Tutorials/README.md)
- [How-To](../How-To/README.md)
