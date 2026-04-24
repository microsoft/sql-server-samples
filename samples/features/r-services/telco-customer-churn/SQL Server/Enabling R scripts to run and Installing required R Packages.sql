--Enabling sp_execute_external_script to run R scripts in SQL Server 2016 and installing package in order to run the Script TelcoChurn-Main.sql and TelcoChurn-Operationalize.sql sucessfully.

--SP_EXECUTE_EXTERNAL_SCRIPT is a stored procedure that execute provided script as argument on external script to a provided language (in this case R language). To enable normal function of this external stored procedure, you must have administrator access to your SQL Server instance in order to run sp_configure command (and set following configuration):

EXECUTE sp_configure;
GO
--To enable execution of external script add an argument:

EXECUTE sp_configure 'external scripts enabled', 1;
GO
--And after that run the reconfiguration as:

RECONFIGURE;
GO

--InstallPackage using sp_execute_external_script
EXECUTE sp_execute_external_script
       @language = N'R'
      ,@script=N'install.packages("ggplot")'
WITH RESULT SETS (( ResultSet VARCHAR(50)));

-- using Download.file command
EXECUTE sp_execute_external_script
       @language = N'R'
      ,@script=N'download.file("https://cran.r-project.org/bin/windows/contrib/3.4/ggplot2_2.1.0.zip","ggplot")
                 install.packages("ggplot", repos = NULL, type = "source")'
WITH RESULT SETS (( ResultSet VARCHAR(50)));

--InstallPackage using sp_execute_external_script
EXECUTE sp_execute_external_script
       @language = N'R'
      ,@script=N'install.packages("gplots")'
WITH RESULT SETS (( ResultSet VARCHAR(50)));

-- using Download.file command
EXECUTE sp_execute_external_script
       @language = N'R'
      ,@script=N'download.file("https://cran.r-project.org/bin/windows/contrib/3.4/gplots_3.0.1.zip","gplots")
                 install.packages("gplots", repos = NULL, type = "source")'
WITH RESULT SETS (( ResultSet VARCHAR(50)));



--InstallPackage using sp_execute_external_script
EXECUTE sp_execute_external_script
       @language = N'R'
      ,@script=N'install.packages("xgboost")'
WITH RESULT SETS (( ResultSet VARCHAR(50)));

-- using Download.file command
EXECUTE sp_execute_external_script
       @language = N'R'
      ,@script=N'download.file("https://cran.r-project.org/bin/windows/contrib/3.4/xgboost_0.4-4.zip","xgboost")
                 install.packages("xgboost", repos = NULL, type = "source")'
WITH RESULT SETS (( ResultSet VARCHAR(50)));


--InstallPackage using sp_execute_external_script
EXECUTE sp_execute_external_script
       @language = N'R'
      ,@script=N'install.packages("qcc")'
WITH RESULT SETS (( ResultSet VARCHAR(50)));

-- using Download.file command
EXECUTE sp_execute_external_script
       @language = N'R'
      ,@script=N'download.file("https://cran.r-project.org/bin/windows/contrib/3.4/qcc_2.6.zip","qcc")
                 install.packages("qcc", repos = NULL, type = "source")'
WITH RESULT SETS (( ResultSet VARCHAR(50)));
