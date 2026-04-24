
# External probe

**Type code:** *External*

External probe type allows running external code as probe. This probe can call any external .NET class implementing `Microsoft.SqlServer.Management.Assessment.IProbeImplementation` interface.

## Implementation properties

Implementation part of the probe definition contains the following parameters.

| Parameter | Required | Type   | Default | Description                       |
|-----------|:--------:|:------:|:-------:|-----------------------------------|
| class     | Required | string |         | The name of the class implementing `IProbeImplementation` |
| assembly  | Optional | string | SQL Assessment API engine assembly|Path to an assembly file containing `class`. If not specified the engine will look for an internal class with the specified name. |

### IProbeImplmenetation interface

The `IProbeImplementation` interface has the following properties. The engine sets their values so the probe implementation could have optional parameters and information about the assessed SQL Server instance or database.

| Property   | Type       | Description                                       |
|------------|:----------:|---------------------------------------------------|
| ServerName | string     | The name of the target server                     |
| TargetName | string     | The name of the assessed instance or the database |
| Urn        | string     | A string identifier of the target object          |
| Parameters | dictionary | A dictionary containing named parameters passed to the probe from the calling check |

After setting all the `IProbeImplementation` properties the engine calls `GetDataAsync` method to retrieve all the data.
