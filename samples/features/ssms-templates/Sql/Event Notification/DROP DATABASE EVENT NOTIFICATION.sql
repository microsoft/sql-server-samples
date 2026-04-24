-- =============================================
-- Drop Database Event Notification Template
-- =============================================
IF EXISTS (SELECT *
             FROM sys.event_notifications
            WHERE name = N'<event_notification_name, sysname, myEventNotification>')
DROP EVENT NOTIFICATION <event_notification_name, sysname, myEventNotification>
ON DATABASE
GO