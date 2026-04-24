# Data transformation: **aggregate**

Takes all data rows returned from probes or previous transformations and calculates aggregate values for specified columns. If [grouping](#grouping) was specified, returns an aggregate row for every group. Returns one row otherwise.

## Paramters

|Parameter|Required|Type|Description|
|-|-|-|-|
|map|Required|Map|Maps column names to [aggregate functions](#aggregate-functions)|
|group|Optional|String or Array of strings|Names of columns used for [grouping](#grouping)|

## Grouping

By default aggregate functions are applied to all data records returned by probes or previous transformations. Optionally, aggregates may be applied to groups of rows having the same value(s) in selected column(s). it works much like `GROUP BY` T-SQL clause.

## Example 1

In this example **blocked_spid** becomes the number of unique non-null **blocked_spid**s, **block_time_min** becomes the minimum of all **block_time_min**s. Other columns are removed.

```json
"transform": {
    "type": "aggregate",
    "map": {
        "blocked_spid": "count",
        "block_time_min": "min"
    }
}
```

## Example 2

In this example the transformation count non-unique non-null **RecoveryUnitId**s.

```json
"transform": {
    "type": "aggregate",
    "map": {
        "RecoveryUnitId": {
            "type": "count",
            "distinct": false
        },
        "blocked_spid": "count",
        "block_time_min": "min"
    }
}
```

## Example 3

In the following example the transform constructs a string containing a comma-separated list of all publications for each **publisher_db**.

```json
"transform": {
    "type": "aggregate",
    "group": "publisher_db",
    "map": {
        "publication": "join"
    }
}
```

## Aggregate Functions

### and/or

Calculates 'and'/'or' aggregate value for boolean values. Null, DBNull, empty string, empty array, and string *'false'* are converted to *false*. Non-empty string, non-empty array, and string *'true'* are converted to *true*.

### array

Collects all values into an array.

### count

Count all values.

|Parameter|Required|Type|Default|Description|
|---|:-:|:-:|:-:|---|
|distinct|Optional|Bool|*true*|If *true* count only distinct values|
|notNull|Optional|Bool|*true*|if *true* count only non-null values|

### join

Converts values to string and joins them into string separated by comma by default.

|Parameter|Required|Type|Default|Description|
|---|:-:|:-:|:-:|---|
|trim|Optional|Bool|*true*|If *true*, trim white space from the beginning and the end of each value|
|separator|Optional|String|*', '*|A string used to separate values|
|limit|Optional|Int|0|When `limit` > 0, `join` returns a string containing not more than first `limit` items with ellipsis replacing the rest. E.g. when `limit`=3, for [1,2,3,4,5] `join` returns "1, 2, 3, ..."|
|distinct|Optional|Bool|*true*|Skips repeating values. E.g. for [*cat*,*lion*,*cat*,*cat*,*tiger*,*lion*] `join` returns *"cat, lion, tiger"*|
|comparison|Optional|Comparison|*CurrentCulture*|Specifies the culture, case, and sort rules to be used for selecting *distinct* values. See [StringComparison Enum](https://docs.microsoft.com/dotnet/api/system.stringcomparison) for allowed values and more details.|

### max/min

Calculates max/min value. For numeric values only.

### sum

Calculates sum of all the values. For numeric values only.

