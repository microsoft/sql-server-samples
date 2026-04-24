
# AzGraph probe

**Type code:** *AzGraph*

This probe runs a Kusto query on Azure resource graph.

## Implementation properties

Implementation part of the probe definition contains the following parameters.

| Parameter | Required | Type   | Default | Description |
|-----------|:--------:|:------:|:-------:|-------------|
| query     | Required | String |         | Kusto query |

Use at-sign '@' to ember parameters into the query string.

## Example

The following qprobe return `@name` for a resource with resource id equal to parameter `@resId`.

```json
...
    "implementation": {
        "query": "Resources | where id =~ @resId | project name"
    }
...
```
