# JSON configuration file format

This section explains the structure of the JSON file with rules and probes.

## Engine configuration

|Property|Property Type|Description|
|-|-|-|
|version|string|Configuration file version. The current version is "0.3".|
|checks|array|Each item is a [Check](#check) object.|
|probes|object|Each property represents a [Probe Family](#probe).|

## Check

|Property|Property Type|Description|
|-|-|-|
|name|string|Short single name. Must be unique.|
|tags|array of strings|A set of tags for the check. Tags represent check groups and categories. A tag can be used instead of the check name in API calls.|
|displayName|string|Long name that is shown to the user.|
|description|string|Long description that explains the purpose of the check.|
|enabled?|bool|Indicates if the check is enabled. Disabled checks are not run for any object. True by default.|
|messge|string|Recommendation text displayed to the user when the check fails. Recommendation text may contain variable references in the `@{variableName}` form. Such references are replaced by string representation of the variable value. The optional format string can be specified for the variable in the `@{variableName:formatString}` form.|
|target?|[SQL Object Pattern](#sql-object-pattern)|Check can be applied to objects that satisfy the pattern. By default matches any object.|
|probes|array of strings|IDs of the [Probe Families](#probe) required by the check.|
|condition?|[Condition Expression](#condition-expression)|A condition expression that must be satisfied by the target object. If the condition expression returns false, the recommendation is generated. True by default.|
|level|string|Severity level: **Information**, **Warning**, or **Critical**.|
|any|[Expression](#expression)|Other properties are treated as check parameters and accessible from check expressions as variables by the name prefixed with the at-sign @. Parameters may refer to variables or other parameters.|

## Probe

A *Probe* is a JSON property. The property name is the probe family ID used in [Checks](#check). The property value is an array of [probe implementations](#probe-implementation). Probe implementations are checked in the order if their target patterns match the target object. The first matching probe will be used to get data. This means that the order of the probes is important. A probe can be comprised by a mix of CLR and SQL implementations.

### Probe implementation

A JSON object. Security is the user responsibility. Probes only read metadata like update logs or server properties; they do not read user data from tables or write anything to databases or instances. Probes do not set any flags or properties.

|Property|Property Type|Description|
|-|-|-|
|type|string|Probe type. Supported values: **SQL**, **WMI**, **External**, **PowerShell**, **CmdShell**, **AzGraph**, **AzMetadata**, **Registry**.|
|target?|[SQL Object Pattern](#sql-object-pattern)|Probe may be applied to objects satisfying the pattern.|
|implementation|object|Any parameters required by the probe. Probes with type="SQL" need a query property containing the SQL command executed to get the probe data. Probes with type="CLR" need a class property specifying the class name and assembly property specifying assembly. Other properties are used to populate a new class instance.|

#### SQL probe implementation

|Property|Property Type|Description|
|-|-|-|
|query|string|T-SQL query. The query can refer to parameters by the name.|

#### External probe implementation

External probe implementation refers to an arbitrary .NET class in the given assembly. The class must implement `IProbeImplementation` interface.

|Property|Property Type|Description|
|-|-|-|
|assembly|string|String specifying assembly to load.|
|class|string|Full class name.|

### SQL Object Pattern

#### Regular expression

Regular expressions are enclosed in slashes: `"/Win*./"`. Regular expression options can be specified after the closing slash. For example, this is the case insensitive search: `"/win.*/i"`. If the string does not start with a slash, it is treated as an exact string match. The string "Linux" is equivalent to `"/^Linux$/"`.

#### Version range list

The version range list is a single [version range](#version-range) or an array of version ranges. A single version range is equivalent to an array containing the only element. The version range list matches any version matching any of its ranges.

```json
"version": [
    "[10.0.4326,10.0.4371]",
    "[10.0.5794,10.50)",
    "[10.50.2806,11.0)",
    "[11.0.2316,)"
]
```

#### Version range

A range of versions is encoded by a string. The string contains one or two versions delimited by the comma and enclosed into optional parenthesis or brackets. If there are two versions, the former version must be less than or equal to the latter. They represent the range boundaries. The version must be specified at least by two numbers separated by the period: major and minor version numbers.

|Version Range|Matches|
|-|-|
|"10.0"|Version 10.0 exactly.|
|"[10.0, 13.0]"|Anything between 10.0 and 13.0, inclusive: 10.0, 10.50, 11.0.345, 13.0.|
|"(10.0, 13.0)"|Anything between 10.0 and 13.0, exclusive: 10.50, 11.0.345. Does not match 10.0 or 13.0.|
|"[10.0, 13.1)"|Anything between 10.0 and 13.1, excluding the right boundary: 10.0, 10.50, 11.0.345, 13.0, 13.0.234. Does not match 13.1.|
|"(10.0, 13.1]"|Anything between 10.0 and 13.1, excluding 10.0.|
|"[10.0,)"|10.0 and abo|
|"(10.0,)"|Above 10.0, but not itself|
|"(,10.0]"|10.0 or below|
|"(,10.0)"|Below 10.0, but not 10.0.|

## Expression

Expressions define calculations made to decide if a recommendation should be given to the user.

### Boolean literals

JSON values true and false are treated as Boolean constants.

### Numeric literals

JSON numbers are treated as decimal constants.

### String literals

String literals represent strings except those starting with the "@" character denoting a reference to a variable.

### Variables

Variables are represented by strings containing their names preceded by the "@" character. Variable values are set by probes and consumed by expressions or recommendation texts.

### Expression JSON object

JSON object with a single property is an expression represented by the property. See [Property Expressions](#property-expressions). JSON object with more than one property is a short version for the AND operation. Its arguments are the object properties. The results are converted into the Boolean type if possible. So these two expressions are equivalent:

```json
expression1: {
    "@version": "10.50.0",
    "@memroySize": 4096
}

expression2: {
    "and": [
        {"@version": "10.50.0"},
        {"@memroySize": 4096}
    ]
}
```

### Property Expressions

Any expression can be represented in a form of a JSON property. The property name is the operation name while the property value is an array of operation arguments. Arguments are any expressions except condition expressions.

When the property name starts with the "@" character, it is not the operation name. The expression is a short variant of the equal operation with the variable as the first argument and the only property value as the second. The following expressions are equivalent:

```json
expression1: {"@memorySize": 4096}

expression2: {
    "equal": [
    "@memorySize",
    4096
    ]
}
```

### Condition Expression

Condition expressions can be any expressions or an array of expressions. An array of expressions is a short version for OR operations. An array of items holds arguments for the operation. The following expressions are equivalent:

```json
"condition": [
    {"@version": "10.50.0"},
    {"@memroySize": 4096}
]

"condition": {
    "or": [
        {"@version": "10.50.0"},
        {"@memroySize": 4096}
    ]
}
```

Note: The short version for "OR" works only as condition expressions while the short version for "AND" works everywhere. The following expressions are equivalent:

```json
"condition": {
    "@version": "10.50.0",
    "@memroySize": 4096
}

"condition": {
    "and": [
        {"@version": "10.50.0"},
        {"@memroySize": 4096}
    ]
}
```
