SELECT
t.[commit_time] AS [CommitTime]
, t.[principal_name] AS [UserName]
, l.EmployeeId
, l.[SSN]
, l.[FirstName]
, l.[LastName]
, l.[Salary]
, l.[ledger_operation_type_desc] AS Operation
FROM [dbo].[Employees_Ledger] l
JOIN sys.database_ledger_transactions t
ON t.transaction_id = l.ledger_transaction_id
ORDER BY t.commit_time DESC