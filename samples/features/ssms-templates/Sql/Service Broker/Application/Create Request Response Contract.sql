-- =============================================
-- Create Request Response Application Template
-- =============================================


--  Create the stored procedure

if exists (select 1 from sys.procedures where [object_id] = OBJECT_ID(N'[dbo].[<ssb-proc-name, sysname, test_proc>]'))
drop procedure [dbo].[<ssb-proc-name, sysname, test-proc>]
GO
SET ANSI_NULLS ON
go
SET QUOTED_IDENTIFIER ON
go

CREATE PROCEDURE [dbo].[<ssb-proc-name, sysname, test-proc>]
   AS declare @message_body varbinary(MAX)

   declare @message_type int
   declare @dialog uniqueidentifier



while (1 = 1)
begin
	begin transaction

-- Receive the next available message from the queue
	
	WAITFOR (
		RECEIVE top(1) -- just handle one message at a time
			@message_type=message_type_id, --the type of message received
			@message_body=message_body,      -- the message contents
			@dialog = conversation_handle    -- the identifier of the dialog this message was received on
			FROM <queue-name, sysname, test_queue>
	), TIMEOUT 1000  -- if the queue is empty for one second, give UPDATE and go away

-- If we didn't get anything, bail out
	if (@@ROWCOUNT = 0)
		BEGIN
			Rollback Transaction
			BREAK
		END

-- Check for the End Dialog message.
	If (@message_type <> 2) -- End dialog message
	BEGIN
-- Send the message back to the sender.
		SEND ON CONVERSATION @dialog  -- send it back on the dialog we received the message on
			MESSAGE TYPE [<Response-message-type, sysname, test_msg_resp>] -- Must always supply a message type
			(@message_body);  -- the message contents (a varbinary(MAX) blob
	END

--  Commit the transaction.  At any point before this, we could roll
--  back - the received message would be back on the queue and the response
--  wouldn't be sent.
	commit transaction
end
go


-- Create the required meta-data

CREATE MESSAGE TYPE <Request-message-type, sysname, test_msg_req> VALIDATION = NONE

CREATE MESSAGE TYPE <Response-message-type, sysname, test_msg_resp> VALIDATION = NONE

CREATE CONTRACT <contract-name, sysname, test_contract>
  ( <Request-message-type, sysname, test_msg_req> SENT BY INITIATOR,
    <Response-message-type, sysname, test_msg_resp> SENT BY TARGET)

CREATE QUEUE <queue-name, sysname, test_queue>

CREATE SERVICE [<service-name, sysname, test_service>]
ON QUEUE <queue-name, sysname, test_queue>

ALTER SERVICE [<service-name, sysname, test_service>]
 ( ADD CONTRACT <contract-name, sysname, test_contract> )

