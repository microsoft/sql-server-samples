-- ================================================
-- Basic Create Security Policy Template
--
-- This template assumes that the inline function
-- and table for the policy exist in the database.
--
-- Use the Specify Values for Template Parameters
-- command (Ctrl-Shift-M) to fill in the parameter
-- values below.
--
-- This block of comments will not be included in
-- the definition of the security policy.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE SECURITY POLICY <Security_Policy_Name, sysname, Security_Policy>
-- Add the filter predicates here
  ADD FILTER PREDICATE <Function_Schema_Name, sysname, dbo>.<Inline_Function_Name, sysname, CheckID>(<Param1, sysname, @Employee_ID>)
    ON <Table_Schema_Name, sysname, dbo>.<Table_Name, sysname, Salaries>
--Set the state on or off
  WITH (STATE = <On_off, onoff, OFF>)

