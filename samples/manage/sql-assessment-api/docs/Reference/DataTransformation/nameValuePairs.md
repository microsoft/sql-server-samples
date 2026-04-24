# Data transformation: **nameValuePairs**

From all data rows returned from probes or previous transformations takes two columns and transposes this two-column table.

## Parameters

|Parameter|Required|Type|Description|
|-|-|-|-|
|keyColumn|Required|String|Key column name used for [transformation](#transformation)|
|valueColumn|Required|String|Value column name used for [transformation](#transformation)|
|map|Required|Map|Maps **keyColumn** values to column names|

## Remarks

This transform takes a name from the **keyColumn** and uses it to create a new column with the corresponding value from the **valueColumn**. If **map** is present, then the value from the **keyColumn** is used as a key to find the new column name in the **map**.

In the following example the source table is transformed to result table. The **Description** column is omitted. **CPU Utilization** and **Disk Free Space** columns are renamed according to the **map**.

## Example 1

Source table:
|Metric|MeasuredValue|Description|
|---|---|---|
|CPU Utilization|0.65|Average CPU utilization|
|NOPM|120|Number of new orders per minute|
|Disk Free Space|15|Disk free space|
|TPM|11236|Number of transactions per minute|


```json
"transform": {
    "type": "nameValuePairs",
    "keyColumn": "Metric",
    "valueColumn": "MeasuredValue",
    "map": {
        "CPU Utilization": "cpu_utilization",
        "Disk Free Space": "disk_space"
    }
}
```

Result table:
|cpu_utilization|NOPM|disk_space|TPM|
|---|---|---|---|
|0.65|120|15|11236|
