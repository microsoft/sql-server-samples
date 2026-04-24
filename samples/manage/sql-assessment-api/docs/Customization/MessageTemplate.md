# Message template

## Overview

A check produces a recommendation message specified in the [__mesasge__](./Rule.md#message) property. The message can contain data returned from a probe or calculated by the check.

Message template resembles [C# string interpolation](https://learn.microsoft.com/dotnet/csharp/language-reference/tokens/interpolated). Data variables can be inserted in curly braces preceded by the 'at' sign '@'.

In the following example a probe returns `@indexName`, `@Schema`, and `@Object` string variables. The API will substitute the references in curly braces with actual values.

```json
"message": "Drop hypothetical @{IndexName} index for @{Schema}.@{Object}"
```

Message template supports format specifiers as well. The specifier must follow the variable name separated by a colon ':'. For more information on formatting values see [How to format numbers, dates, enums, and other types in .NET](https://learn.microsoft.com/dotnet/standard/base-types/formatting-types)

In the following example the number `@fragmentation` will be multiplied by 100, rounded to 2 digits after decimal point, and decorated with percent sign '%'.

```json
"message": "Current fragmentation level is @{fragmentation:P2}"
```

Output:

```plain
Current fragmentation level is 37.20%
```

Formatting for string values is extended. The format string will inserted into the resulting message if the value is not null and not an empty string. The pound sign '#' is replaced by the string value itself. This could be useful for adding sentence parts when additional information is present.

Take the following example:

```json
"message": "Create index on @{Table} with key columns @{KeyCols}@{IncludedCols: and included columns: #}"
```

When `@IncludedCols` is empty the message would be

```plain
Create index on MyTable with key columns Id, Name
```

When `@IncludedCols` is contains names of included columns "_SpaceAvailable, CPULoad_", tha message will be:

```plain
Create index on MyTable with key columns Id, name and included columns: SpaceAvailable, CPULoad
```
