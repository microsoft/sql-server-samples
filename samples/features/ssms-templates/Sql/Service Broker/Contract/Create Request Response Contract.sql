-- =============================================
-- Create Request Response contract Template
-- =============================================
-- =============================================
-- Author:		<Author,,>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE CONTRACT <contract-name, sysname, test_contract>
	AUTHORIZATION <owner-name ,database-user  ,dbo>
	( <message-type-name, sysname, to_msg> SENT BY INITIATOR,
      <message-type-name2, sysname, from_msg> SENT BY TARGET )
