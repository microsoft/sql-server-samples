# Data transformation: **rename**

Renames any data column.

## Parameters

|Parameter|Required|Type|Description|
|-|-|-|-|
|[map](#map)|Required|Map|Maps new names to old ones|

## Map

Rename map is a JSON objects setting correspondence between new names and old ones. Each property name is the *new* column name. The value sets the name of the old column to be renamed. In the following example column **Log File Size (Byte)** will be renamed to *size*.

## Example 1

```json
"transform": {
    "type": "rename",
    "map": {
        "id": "Archive #",
        "size": "Log File Size (Byte)",
        "date": "Date"
    }
}
```