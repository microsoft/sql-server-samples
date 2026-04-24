# Overriding Default Thresholds

Some of the default thresholds provided by the SQL Assessment API might not fit your current infrastructure at the moment of the assessment. In such scenarios, you can easily override them with your own values.

Let's consider an example of using the **FullBackup** rule that validates whether the date your backup was created goes beyond the threshold specified in the rule.

To invoke the assessment, you can run the following command:

```PowerShell
Invoke-SqlAssessment -Check FullBackup | Select TagerObject, Message
```

Depending on the number of objects, the output will be similar to the following one:

```
TargetObject    Message
-------------   --------
[DevTest]       Create full backup. Last full backup is over 7 days old
[Prototype]     Create full backup. Last full backup is over 7 days old
```

As you can see, the output tells us that there are two databases that have their backups created more than 7 days ago, which is the default threshold.

Let's say you need to change this rule to validate backups that were created more than 3 days ago instead of 7. You can do this by creating a new json file. Such a file would then be acting as an additional configuration that overrides the default thresholds. As per this example, we will create a file called `BackupPolicy.json` and add the following contents to this file:

```json
{
    //Sets the schema version
    "schemaVersion": "1.0",

    //Sets the version
    "version": "1.0",

    //Sets the rule name
    "name": "Backup Policy",

    //Sets the override for the specified rule
    "rules":
    [
        {
            //Sets the type, which is 'override'
            "itemType": "override",

            //Sets the name of the rule that should be overridden
            "id": "FullBackup",

            //Sets the new threshold
            "threshold": 3
        }
    ]
}
```

Then you can save this file to whatever place you need and invoke the assessment, as the following example demonstrates.

```PowerShell
Invoke-SqlAssessment -Check FullBackup -Configuration .\BackupPolicy.json | Select TargetObject, Message
```

Here, you are basically using the same command, as shown in the example above, but extended with `-Configuration .\BackupPolicy.json`. This command instructs the assessment to use a custom configuration file that keeps your overrides.

The output in this case would be similar to the following one:

```
TargetObject    Message
-------------   --------
[DevProd]       Create full backup. Last full backup is over 3 days old
[TestDB]        Create full backup. Last full backup is over 3 days old
[DevTest]       Create full backup. Last full backup is over 3 days old
[Prototype]     Create full backup. Last full backup is over 3 days old
```

As you can see, the output is now different from the first one; now it shows all the databases, the backup date of which is over 3 days.
