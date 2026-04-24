# PowerShell probe

**Type code:** *PowerShell*

PowerShell probes execute commands in PowerShell (fx) on the target machine and return the pipeline output in the `@Output` variable.

## Implementation parameters

PowerShell probe implementation has the following parameters:

| Parameter | Required | Type   | Default | Description                   |
|-----------|:--------:|:------:|:-------:|-------------------------------|
| command   | Required | string |         | PowerShell command to execute |

Use the `$` (dollar) sign in the `command` text to access probe parameters passed by checks.

Use the `.` (dot) notation to access the object properties. For example, if the returned object is a string, then `@Output.Length` returns its length.

NOTE: Pipeline output is not shown on the screen. For example, the `Write-Host` output is ignored.

## Example

The following probe enumerates file system items in the current dirrectory:

```json
{
    "type": "PowerShell",
    "target": …,
    "implementation": {
        "command": 'Get-ChildItem'
    }
}
```

Output:

| @Output     | @Output.FullName                | @Output.Parent.Name |
|-------------|---------------------------------|---------------------|
| "UV"        | "C:\Windows\system32\UV"        | "system32"          |
| "UV-FOGRA"  | "C:\Windows\system32\UV-FOGRA"  | "system32"          |
| "x3dom.css" | "C:\Windows\system32\x3dom.css" | "system32"          |
| "x3dom.js"  | "C:\Windows\system32\x3dom.js"  | "system32"          |
