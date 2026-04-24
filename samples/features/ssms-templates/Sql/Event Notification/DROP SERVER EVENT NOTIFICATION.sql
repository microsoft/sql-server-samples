-- =============================================
-- Drop Server Event Notification Template
-- =============================================
IF EXISTS (SELECT *
             FROM sys.server_event_notifications
            WHERE name = N'<event_notification_name, sysname, myEventNotification>')
DROP EVENT NOTIFICATION <event_notification_name, sysname, myEventNotification>
ON SERVER
GO