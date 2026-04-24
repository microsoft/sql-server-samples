-- =============================================
-- Basic Create Target Service Template
-- =============================================

CREATE SERVICE [<service-name, sysname, test_service>]
   ON QUEUE <queue-name, sysname, test_queue>
   (<contract-name, sysname, test_contract> )

