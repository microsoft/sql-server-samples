# WMI probe

**Type code:** *WMI*

WMI probes run WMI queries.

A WMI query returns a number of WMI objects. Each object is processed as a separate row. `@Output` variable represents the object. Use dot notation to access object's properties: `@Output.BlockSize`.

## Implementation properties

Implementation part has the following properties.

|Parameter|Required|Type  |Default|Description                   |
|---------|:------:|:----:|:-----:|------------------------------|
|query    |Required|String|       |WMI query returning probe data|
|methods  |Optional|Map   |       |List of WMI methods to be called on selected WMI objects|

### WMI methods

To call a WMI method mention its name as a property *value* of the `methods` JSON object. The property's name is one for the variable where the result will be stored. In [Example 3](#example-3) the `@da` variable stores the value returned from the **DefragAnalysis** method.

## Examples

### Example 1

Simple WMI probe returns name and block size for volumes.

```JSON
{
    "type": "WMI",
    "target": …,
    "implementation": {
        "query": "SELECT Name, BlockSize FROM Win32_Volume WHERE Capacity <> NULL"
    }
}
```

Output:

| @Output.Name                                       | @Output.BlockSize |
|----------------------------------------------------|------------------:|
| E:\\                                               | 4096              |
| C:\\                                               | 4096              |
| \\?\Volume{b9878a89-2e73-4790-8576-9c8217b2fba7}\\ | 4096              |
| M:\\                                               | 4096              |
| G:\\                                               | 4096              |
| R:\\                                               | 4096              |
| \\?\Volume{41c4c545-aad7-4a8c-86e5-11a52611a81d}\\ | 1024              |

### Example 2

Use the `$` (dollar) sign to access probe parameters passed by checks.

```JSON
{
    "type": "WMI",
    "target": {
        "type": "Server",
        "platform": "Windows",
        "engineEdition": "OnPremises",
        "version": "[11.0,)"
    },
    "implementation": {
        "query": "SELECT Name, StartingOffset FROM Win32_DiskPartition WHERE StartingOffset < $threshold"
    }
}
```

### Example 3

Call a WMI method opn each WMI object returned by a WMI query.

```json
{
    "type": "WMI",
    "target": {
        "type": "Server",
        "platform": "Windows",
        "engineEdition": "OnPremises",
        "version": "[11.0,)"
    },
    "implementation": {
        "query": "SELECT DeviceID, Name FROM Win32_Volume WHERE DriveType=3 AND Name LIKE '_:\\\\'",
        "methods": {
            "da": "DefragAnalysis"
        }
    }
}
```
