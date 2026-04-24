
-- =============================================
-- Basic Create Service Broker Endpoint Template
-- =============================================

CREATE ENDPOINT <endpoint_name, sysname, test_endpoint>
AS TCP (
   LISTENER_PORT = <listenerPort, int, 4022>
   )
FOR SERVICE_BROKER (
   AUTHENTICATION = WINDOWS
   )

