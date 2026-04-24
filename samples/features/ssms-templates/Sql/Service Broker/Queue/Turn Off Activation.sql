-- =============================================
-- Turn Activation Off Template
-- =============================================

ALTER QUEUE <queue-name, sysname, test_queue>
   WITH ACTIVATION ( STATUS =  OFF )
