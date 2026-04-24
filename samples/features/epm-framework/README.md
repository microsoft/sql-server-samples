The Enterprise Policy Management Framework is a reporting solution on the state of the enterprise against a desired state defined in a policy. Extend Policy-Based Management to all SQL Server instances in the enterprise. Centralize and report on the policy evaluation results.

The Enterprise Policy Management Framework (EPM) is a solution to extend SQL Server Policy-Based Management to all versions of SQL Server in an enterprise, including SQL Server 2000 and SQL Server 2005. The EPM Framework will report the state of specified SQL Server instances against policies that define the defined intent, desired configuration, and deployment standards.

When the Enterprise Policy Management Framework (EPM) is implemented, policies will be evaluated against specified instances of SQL Server through PowerShell. This solution will require at least one instance of SQL Server. The PowerShell script will run from this instance through a SQL Server Agent job or manually through the PowerShell interface. The PowerShell script will capture the policy evaluation output and insert the output to a SQL Server table. SQL Server Reporting Services reports will deliver information from the centralized table.

This solution requires the following components are configured in your environment. All SQL Server requirements listed below may be executed from and managed on the same instance:
- SQL Server instance to store policies
- SQL Server instance to act as the Central Management Server
- SQL Server instance to execute the PowerShell script
- SQL Server management database and policy history table to archive policy evaluation results
- SQL Server Reporting Services to render and deliver policy history reports

For all the above, it's recommended that you use the highest version of SQL Server in the environment.
