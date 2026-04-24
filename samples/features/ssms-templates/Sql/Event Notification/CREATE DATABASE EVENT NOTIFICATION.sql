-- =============================================
-- Create Database Event Notification Template
-- =============================================
IF EXISTS (SELECT *
             FROM sys.event_notifications
            WHERE name = N'<event_notification_name, sysname, event_name>')
DROP EVENT NOTIFICATION <event_notification_name, sysname, event_name>
ON DATABASE
GO
CREATE EVENT NOTIFICATION <event_notification_name, sysname, event_name>
ON DATABASE
WITH FAN_IN
FOR <event_type, sysname, ALTER_TABLE >
TO SERVICE 'broker_service', <broker_instance, sysname, 'current database'>
GO