# Data transformation: **defaultValue**

Replaces values with strings.

## Parameters

|Parameter|Required|Type|Description|
|-|-|-|-|
|[map](#map)|Required|MapOfMaps|Maps columns to value maps|

## map

String map is a JSON objects defining a string-to-value mapping for one or more columns. In the following example value *2* in column **a** will be replaced with the word *'two'*. The same word *two* will be assigned to column **b** if it's value is *'w'*.

## Example 1

```json
"transform": {
    "type": "defaultValue",
    "map": {
        "a":{
            "one"  : 1,
            "two"  : 2,
            "three": 3
        },
        "b":{
            "one"  : "o",
            "two"  : "w",
            "three": "r"
        }
    }
}
```