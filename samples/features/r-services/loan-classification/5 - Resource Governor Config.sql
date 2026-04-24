create external resource pool "lcerp1" with (affinity numanode = (0));

create external resource pool "lcerp2" with (affinity numanode = (1));



create resource pool "lcrp1" with (affinity numanode = (0));

create resource pool "lcrp2" with (affinity numanode = (1));



create workload group "rg0" using "lcrp1", external "lcerp1";

create workload group "rg1" using "lcrp2", external "lcerp2";



USE [master]

GO

SET ANSI_NULLS ON

GO

SET QUOTED_IDENTIFIER ON

GO

CREATE function [dbo].[assign_external_resource_pool]()

returns sysname

with schemabinding

as

begin

return concat('rg', @@SPID%2);

end;

GO

