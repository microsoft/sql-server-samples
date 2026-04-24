# attr::target:: variables

[Automatic variables](./README.md) in **attr::target::** namespace include the data which matched the [target pattern](../Rule.md#target).

| Variable name               | Type    | Description       |
|-----------------------------|---------|-------------------|
| attr::target::version       | version | Target SQL Server [version](../TargetPattern.md#version)                              |
| attr::target::platform      | string  | Target SQL Server host [platform](../TargetPattern.md#platform) (e.g. Windows, Linux) |
| attr:target::engine_edition | string  | Target [engine edition](../TargetPattern.md#engineedition)                            |
| attr::target::server_name   | string  | Target [server name](../TargetPattern.md#servername)                                  |
| attr::target::machine_type  | string  | Target [machine type](../TargetPattern.md#machinetype)                                |
| attr::target::urn           | string  | Target object URN |
