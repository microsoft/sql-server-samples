-- =============================================
-- Create Queue with Activation Template
-- =============================================
-- =============================================
-- Author:		<Author,,>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE QUEUE <queue-name, sysname, test_queue>
   WITH
   STATUS = ON,
   RETENTION = OFF ,
   ACTIVATION (
		STATUS = ON,
		PROCEDURE_NAME = <proc-name, sysname, test_procedure> ,
		MAX_QUEUE_READERS = <maxreaders, int, 1>,
		EXECUTE AS <execute-options,,SELF> ),
   POISON_MESSAGE_HANDLING (STATUS = ON)
   ON <filegroup,,[DEFAULT]>