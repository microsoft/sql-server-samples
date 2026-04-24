# Role requirement

Specifies current user roles required for running this probe.

## Name format

__role__

## Supported values

SQL Server role names.

## Examples

```json
"requires": {
    "role": [
        "bulkadmin",
        "diskadmin"
    ]
}
```

## See also

- [Probe requirements](./README.md)
