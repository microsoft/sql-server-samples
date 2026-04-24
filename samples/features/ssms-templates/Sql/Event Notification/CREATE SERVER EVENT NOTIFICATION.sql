-- =============================================
-- Create Server Event Notification Template
-- =============================================
IF EXISTS (SELECT *
             FROM sys.server_event_notifications
            WHERE name = N'<event_notification_name, sysname>')
DROP EVENT NOTIFICATION <event_notification_name, sysname>
ON SERVER
GO
CREATE EVENT NOTIFICATION <event_notification_name, sysname>
ON SERVER
WITH FAN_IN
FOR <event_type, sysname>
TO <broker_instance, sysname>
GO