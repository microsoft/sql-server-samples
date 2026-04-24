# Data Transformation

Sometimes data needs to go through series of transformations.

When dta comes in an unconvenient format, a transformation can be applied in the probe implementation. For example, the following T-SQL query returns `host_release` as a string like '10.0.19044.2006'.

```SQL
SELECT host_platform, host_release
FROM sys.dm_os_host_info
```

While it is possible to parse the string in T-SQL, a transformation make the code more readable and easier to create and maintain:

```json
"implementation": {
    "query": "SELECT host_platform, host_release FROM sys.dm_os_host_info",
    "transform": {
        "type": "parse",
        "map": {
            "host_release": "/^(?<major>\\d+)\\.(?<minor>\\d+)"
        }
    }
}
```

Transformations can be applied in [probe references](./ProbeReference.md) to increase probe reuse. When one check needs an average value for some metric while another best practice involves maximum for the same metric. Both checks can have references to the same probe but each applies its own specific transformation. In this case not only the probe code is reused, but the data is reused as well, because the probe will be called only once.

See [Data transformation reference](../Reference/DataTransformation/README.md) for more details.