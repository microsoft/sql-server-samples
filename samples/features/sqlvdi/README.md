# SQLVDI
This folder contains the latest files and samples required to build a SQL Server VDI based backup/restore application.

A new **VDC_Complete** command was added to SQLVDI that indicates SQL Server has completed sending data to the VDI client. Therefore, the VDI client will be able to finish the backup before it sends response to SQL Server.

More details about this improvement in the SQLVDI protocol can be found in [KB3188454: Enhance VDI Protocol with VDC_Complete command in SQL Server] (https://support.microsoft.com/en-us/kb/3188454)

The following implementations have to be applied to your VDI client:

1. Request the new VDI feature VDF_RequestComplete.
2. If SQL Server supports the VDC_Complete command, it will return a not NULL response.
3. Otherwise, it would return a NULL response for the requested feature.

The code sample here shows how to request the feature: 
```
m_pvdiComponents->m_pvdConfig->features = VDF_RequestComplete;
printf("Requested features to SQL Server: 0x{0:X}", m_pvdiComponents->m_pvdConfig->features);
```
Determine whether the SQL Server supports the new VDC_Complete command by using the GetConfiguration function.

```
hr = m_pvdiComponents->m_pvdDeviceSet->GetConfiguration(timeout, m_pvdiComponents->m_pvdConfig);

       if (!(m_pvdiComponents->m_pvdConfig->features & VDF_CompleteEnabled))
       {
              printf("Server does not support VDC_Complete.");
              return VD_E_NOTSUPPORTED;
       }
```
When you process the VDI messages that are fetched by the GetCommand function, add an additional case statement to process the VDC_Complete command.
```
case VDC_Complete:
              // Close the media and ensure that book keeping is completed.
              backupMedia->Close();
              completionCode = ERROR_SUCCESS;
              break;
```
The *SQL Server Backup Simulator* can be downloaded [here](https://github.com/Microsoft/tigertoolbox/releases)
