# Registry probe

**Type code:** *Registry*

Registry probes obtain data from the target machine registry.

## Implementation parameters

Registry probe implementation has the following parameters.

| Parameter | Required | Type   | Default | Description                       |
|-----------|:--------:|:------:|:-------:|-----------------------------------|
| query     | Required | object |         | Tree-like structure specifying Registry keys and values to collect see [Registry query](#registry-query) |
| instance  | Optional | bool   | *false* | Indicates whether the probe should return data specific to this SQL Server instance see [Instance specific data](#instance-specific-data) |

### Registry query

Registry query is a complex JSON object.

Top-level properties represent registry hives including *HKEY_LOCAL_MACHINE* and *HKEY_CURRENT_USER*.

Each top-level property value is another JSON object. Its properties represent registry keys. The property name is the full path from the hive to the key.

Use the `*` (asterisk) symbol at any level to enumerate all keys. The key name replacing * will be returned in `@RegistryKeyName` variable.

The value for each key property is an array of registry value names to read. Multi-string values are read as multiple string values with the same name.

### Instance specific data

When `instance` property is *true*, the probe replaces **MSSQLSERVER** in paths with registry path specific for this SQL Server instance. E.g. the following registry path:

```
Software\Microsoft\MSSQLSERVER\SQLServerAgent
```

will be replace with the following instance-specific one:

```
Software\Microsoft\Microsoft SQL Server\MSSQL12.SQL2014\SQLServerAgent
```

where **MSSQL12.SQL2014** is the SQL Server instance name.

### Example 1

The following registry query returns 2 values for for system hardware. Please, note how multi-string value is handled as multiple strings. Use [join aggregate function](../DataMorphs/aggregate.md#join) to merge them when needed.

```json
"probes": {
  "MuRegistryProbe": [
    {
      "type": "Registry",
      "target": { "type": "Server" },
      "implementation": {
        "query": {
          "HKEY_LOCAL_MACHINE":{
            "HARDWARE\\DESCRIPTION\\System": [
              "Identifier",
              "SystemBiosVersion"
            ]
          }
        }
      }
    }
  ]
}
```

Output:

| @Identifier        | @SystemBiosVersion            |
|--------------------|-------------------------------|
| "AT/AT COMPATIBLE" | "ALASKA - 1072009"            |
| "AT/AT COMPATIBLE" | "3802"                        |
| "AT/AT COMPATIBLE" | "American Megatrends - 5000C" |

### Example 2

Use asterisk '*' to enumerate all subkeys of the given key. The following registry query returns processor id and an identifier of its vendor:

```json
{
  "type": "Registry",
  "target": { "type": "Server" },
  "implementation": {
    "query": {
      "HKEY_LOCAL_MACHINE":{
        "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\*": [
          "VendorIdentifier"
        ]
      }
    }
  }
}
```

Output:

| @RegistryKeyName | @VendorIdentifier |
|------------------|-------------------|
| 0                | "Genuine Intel"   |
| 1                | "Genuine Intel"   |
| 2                | "Genuine Intel"   |
| 3                | "Genuine Intel"   |

### Example 3

The following registry query gets an identifier for each hardware item.

```json
{
  "HKEY_LOCAL_MACHINE": {
    "HARDWARE\\DESCRIPTION\\*": [
        "Identifier"
    ]
  }
}
```

### Example 4

Use at-sign '@' to insert probe parameters int the registry query. The following check gets two registry keys `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\test` and `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\some\test`, and compares each to  the 'result' string.

```json
"rules": [
    {
      "id": "MyKeys",
      "itemType": "definition",
      "target": {
        "type": "Server",
        "platform": "Windows"
      },
      "displayName": "My custom keys",
      "message": "The current key is @{test}",
      "testParam": "test",
      "resultParam": "result",
      "hiveParam": "Policies",
      "condition": {
        "@test": "@resultParam"
      },
      "probes": [
        {
          "id": "myprobe",
          "params": {
            "hiveParam": "@hiveParam",
            "testParam": "@testParam"
          }
        }
      ]
    }
  ],
  "probes": {
    "myprobe": [
      {
        "type": "Registry",
        "target": {
          "type": "Server",
          "platform": "Windows",
          "instance": true
        },
        "implementation": {
          "query": {
            "HKEY_LOCAL_MACHINE": {
              "SOFTWARE\\@{hiveParam}": [ "@{testParam}" ],
              "SOFTWARE\\@{hiveParam}\\Microsoft\\some": [ "@{testParam}" ]
            }
          }
        }
      }
    ]
  }
```

