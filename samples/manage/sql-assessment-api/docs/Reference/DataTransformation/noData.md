# Data transformation: **noData**

Defines a record returned when the probe(s) or previous transformations produced no data.

When no data comes from probes, the check passes without calculating the value for condition. this transformation allows processing empty data sets. You can use optional [presenceFlag](#presenceFlag) parameter to apply special logics in the condition.

## Parameters

|Parameter|Required|Type|Description|
|-|-|-|-|
|[define](#define)|Required|Map|Defines default columns and their values|
|[presenceFlag](#presenceFlag)|Optional|String|Indicates if data was present|

## define

The record definition is a JSON objects setting a default value for each data column. In the following example, in case of missing data **InUse** = *2*, **Name** = *'master'*.

## Example 1

```json
"transform": {
    "define": {
        "InUse": 0,
        "Name": "master"
}
```

## presenceFlag

Presence flag is a boolean variable indicating if data was present. Use `presenceFlag` to specify variable name, which will be set to *true* when data was present and *false* otherwise. In the following example, in case when some data was produced by probes or previous transformations **dataFound** is *true*, otherwise it's *false*.

## Example 2

```json
"transform": {
    "presenceFlag": "dataFound",
    "define": {
        "InUse": 0,
        "Name": "master"
}
```