# Data transformation: **defaultValue**

Seta default values for data columns. The default value is used when the column does not contain any data.

## Paramters

|Parameter|Required|Type|Description|
|-|-|-|-|
|[map](#map)|Required|Map|Maps names to default values|

## map

Default value map is a JSON objects setting a default value for each data column. In the following example column **automatic_soft_NUMA_disabled** has default value *0*.

## Example 1

```json
"transform": {
    "type": "defaultValue",
    "map": {
        "automatic_soft_NUMA_disabled": 0
    }
}
```