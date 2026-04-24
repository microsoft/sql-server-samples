# Creating Custom Rules

Sometimes rulesets that come right out of the box after installing the SQL Assessment API might not be enough to validate your environment as required. In such cases, you can simply write your own rulesets.

A typical [ruleset](../Customization/RulesandProbes.md) &mdash; a JSON file &mdash; consists of two blocks: [rules](#rules) and [probes](#probes).

## Rules

The **Rules** block defines the rule structure. It says which objects in your environment should be assessed, which versions of these objects should be considered during the assessment, the platform that hosts the objects being assessed, and so on.
Usually, rules are best practices or company internal policies that should be applied to SQL Server configurations. If any of these configurations violates conditions specified in the rule, the rule throws alerts, pointing at certain areas within your environment that should be changed in order to comply with the best practices. These alerts are represented as messages that give a short and straightforward advice on how to mitigate the issue. Alerts also contain help links to the Microsoft pages when you can get comprehensive instructions on how to configure certain things to avoid potential security and performance issues.

The following is an example of a rule:

```json
{
    //Target describes a SQL Server object the check is supposed to run against
    "target":
    {
        //This check targets an object of the Database type
        "type": "Database",

        //Applies to SQL Server 2016 and higher
        //Another example: "[12.0,13.0)" reads as "any SQL Server version >= 12.0 and < 13.0"
        "version": "[13.0,)",

        //Applies to SQL Server on Windows and Linux
        "platform": "Windows, Linux",

         //Applies to SQL on Premises and Azure SQL Managed Instance. Here you can also filter specific editions of SQL Server
        "engineEdition": "OnPremises, ManagedInstance",

        //Applies to any database excluding master, tempdb, and msdb
        "name": { "not": "/^(master|tempdb|model)$/" }
    },

    //Rule ID
    "id": "QueryStoreOn",

    //Can be "definition" or "override". The former is to declare a rule, the latter is to override/customize an existing rule. See also 'DisablingBuiltInChecks_sample.json'
    "itemType": "definition",

    //Tags combine rules in different subsets
    "tags": [ "CustomRuleset", "Performance", "QueryStore", "Statistics" ],

    //Short name for the rule
    "displayName": "Query Store should be active",

    //A more detailed explanation of a best practice or policy that the rule check
    "description": "The Query Store feature provides you with insight on query plan choice and performance. It simplifies performance troubleshooting by helping you quickly find performance differences caused by query plan changes. Query Store automatically captures a history of queries, plans, and runtime statistics, and retains these for your review. It separates data by time windows so you can see database usage patterns and understand when query plan changes happened on the server. While Query Store collects queries, execution plans and statistics, its size in the database grows until this limit is reached. When that happens, Query Store automatically changes the operation mode to read-only and stops collecting new data, which means that your performance analysis is no longer accurate.",

     //Usually, it's for recommendation what user should do if the rule raises up an alert
    "message": "Make sure Query Store actual operation mode is 'Read Write' to keep your performance analysis accurate",

    //Reference material
    "helpLink": "https://docs.microsoft.com/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store",

    //List of probes that are used to get the required data for this check. See below to know more about probes.
    "probes": [ "Custom_DatabaseConfiguration" ],

    //Condition object is to define "good" and "bad" state, the latter is when the rule should raise an alert. When the condition is true, it means that the checked object complies with the best practice or policy. Otherwise, the rule raises an alert (it actually adds its message to the resulting set of recommendations)
    "condition":
    {
        //It means that the variable came from the probe should be equal to  2
        "equal": [ "@query_store_state", 2 ]
    }
}

```

## Probes

The **Probes** block defines the way how to get the required data to check compliance with the rule. Probes are invoked during the assessment. They use queries to obtain data from your environment. This data is then evaluated and based on this evaluation, the rule can tell whether your environment is in compliance with the best practices or not. If not, the rule fires, telling you exactly what should be changed in order to avoid both performance degradation and security risks.

The following is an example of a probe:

```json
//Probe name is used to reference the probe from a rule
//Probe can have a few implementations that will be used for different targets
//This probe has two implementations for different version of SQL Server
"Custom_DatabaseConfiguration":
[
    {
        //Probe uses a T-SQL query to get the required data. Use 'CLR' for assemblies.
        "type": "SQL",

         //Probes have their own target, usually to separate implementation for different versions, editions, or platforms. Probe targets work the same way as rule targets do.
        "target":
        {
            "type": "Database",

            //This target is for SQL Server of versions prior to 2014
            "version": "(,12.0)",
            "platform": "Windows, Linux",
            "engineEdition": "OnPremises, ManagedInstance"
        },

        //Implementation object with a T-SQL query. This probe is used in many rules, that's why the query return so many fields
        "implementation":
        {
            "query": "SELECT db.is_auto_create_stats_on, db.is_auto_update_stats_on, 0 AS query_store_state, db.collation_name, (SELECT collation_name FROM master.sys.databases (NOLOCK) WHERE database_id = 1) AS master_collation, db.is_auto_close_on, db.is_auto_shrink_on, db.page_verify_option, db.is_db_chaining_on, NULL AS is_auto_create_stats_incremental_on, db.is_trustworthy_on, db.is_parameterization_forced FROM [sys].[databases] (NOLOCK) AS db WHERE db.[name]=@TargetName"
        }
    },

    //This implementation object is to get the required data from SQL Server 2014 (look at target.version)
    {
        "type": "SQL",
        "target":
        {
            "type": "Database",
            "version": "[12.0, 13.0)",
            "platform": "Windows, Linux",
            "engineEdition": "OnPremises, ManagedInstance"
        },
        "implementation":
        {
            "query": "SELECT db.is_auto_create_stats_on, db.is_auto_update_stats_on, 0 AS query_store_state, db.collation_name, (SELECT collation_name FROM master.sys.databases (NOLOCK) WHERE database_id = 1) AS master_collation, db.is_auto_close_on, db.is_auto_shrink_on, db.page_verify_option, db.is_db_chaining_on, db.is_auto_create_stats_incremental_on, db.is_trustworthy_on, db.is_parameterization_forced FROM [sys].[databases] (NOLOCK) AS db WHERE db.[name]=@TargetName"
        }
    },

    //This implementation object is to get the required data from SQL Server 2016 and up (look at target.version)
    {
        "type": "SQL",
        "target":
        {
            "type": "Database",
            "version": "[13.0,)",
            "platform": "Windows, Linux",
            "engineEdition": "OnPremises, ManagedInstance"
        },
        "implementation":
        {
             //Use this key if your query requires to run on a database that is being assessed (it's a replacement for 'USE <DATABASENAME>;')
            "useDatabase": true,
            "query": "SELECT db.is_auto_create_stats_on, db.is_auto_update_stats_on, (SELECT CAST(actual_state AS DECIMAL) FROM [sys].[database_query_store_options]) AS query_store_state, db.collation_name, (SELECT collation_name FROM master.sys.databases (NOLOCK) WHERE database_id = 1) AS master_collation, db.is_auto_close_on, db.is_auto_shrink_on, db.page_verify_option, db.is_db_chaining_on, db.is_auto_create_stats_incremental_on, db.is_trustworthy_on, db.is_parameterization_forced FROM [sys].[databases] (NOLOCK) AS db WHERE db.[name]=@TargetName"
        }
    }
]
```

The complete example is available in the [MakingCustomChecks_sample](MakingCustomChecks_sample.json) file.

You can also build more complex rules by applying certain conditions and using different kinds of operators, as described in [Customization](../Customization)
