# Local Variables

A rule can define local variables available for conditions and message templates. Local variables are any expressions involving literals, probe data, and transformation results.

```json
{
    "probes": ["SysDmOsSysInfo"],
    "locals": {
        "workers": {"sub": [ "@max_workers_count", 1 ] }
    },
    "message": "Workers = @{workers}.",
    "condition": {
        "lt": [ 0, "@workers" ],
        "lt": [ "@workers", 4 ]
    }
}
```