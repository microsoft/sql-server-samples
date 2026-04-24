# CMD shell probe

**Type code:** *CMD*

CmdShell probes execute CMD.EXE shell commands and return text lines in the `@stdout` variable.

## How to use

| Parameter | Required | Type   | Default | Description             |
|-----------|:--------:|:------:|:-------:|-------------------------|
| command   | Required | string |         | Shell command to execute|

Each line returned by the command it returned as separate data row with a single `@stdout` column. Use the Regex parser transformation to extract data from the `@stdout` variable.

## Example

The following probe lists file system entries in the current directory:

```json
{
    "type": "CmdShell",
    "target": …,
    "implementation": {
        "command": "dir"
    }
}
```

Output:

| Row | @stdout                                             |
|-----|-----------------------------------------------------|
|  0  | "03/18/2017 06:52 AM    \<DIR\>          UV"        |
|  1  | "03/18/2017 06:52 AM    \<DIR\>          UV-FOGRA"  |
|  2  | "03/16/2017 03:21 PM               6,419 x3dom.css" |
|  3  | "03/16/2017 03:21 PM             926,910 x3dom.js"  |
