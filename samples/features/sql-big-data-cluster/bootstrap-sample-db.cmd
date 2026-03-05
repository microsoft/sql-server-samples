@echo off
REM bootstrap sample database CMD script
setlocal enableextensions
setlocal enabledelayedexpansion
set CLUSTER_NAMESPACE=%1
set SQL_MASTER_ENDPOINT=%2
set KNOX_ENDPOINT=%3
set AW_WWI_SAMPLES=%4
set SQL_MASTER_PORT=%5
set KNOX_PORT=%6
set STARTUP_PATH=%~dp0
set TMP_DIR_NAME=%~nx0

if NOT DEFINED CLUSTER_NAMESPACE goto :usage
if NOT DEFINED SQL_MASTER_ENDPOINT goto :usage
if NOT DEFINED KNOX_ENDPOINT goto :usage
if NOT DEFINED AW_WWI_SAMPLES set AW_WWI_SAMPLES=no
if NOT DEFINED SQL_MASTER_PORT set SQL_MASTER_PORT=31433
if NOT DEFINED KNOX_PORT set KNOX_PORT=30443

set SQL_MASTER_INSTANCE=%SQL_MASTER_ENDPOINT%,%SQL_MASTER_PORT%
set KNOX_ENDPOINT=%KNOX_ENDPOINT%:%KNOX_PORT%
set SQLCMDSERVER=%SQL_MASTER_INSTANCE%
if DEFINED AZDATA_USERNAME set SQLCMDUSER=%AZDATA_USERNAME%
if DEFINED AZDATA_PASSWORD set SQLCMDPASSWORD=%AZDATA_PASSWORD%
if DEFINED AZDATA_PASSWORD set KNOX_PASSWORD=%AZDATA_PASSWORD%

if NOT DEFINED SQLCMDUSER (
    set BCP_CREDENTIALS=-T
) else (
    set BCP_CREDENTIALS=-U%SQLCMDUSER% -P%SQLCMDPASSWORD%
)

for %%F in (sqlcmd.exe bcp.exe kubectl.exe curl.exe) do (
    echo Verifying %%F is in path & CALL WHERE /Q %%F || GOTO exit
)

pushd "%tmp%"
md %TMP_DIR_NAME% >NUL 2>NUL
cd %TMP_DIR_NAME%

if NOT EXIST tpcxbb_1gb.bak (
    echo Downloading sample database backup file...
    %DEBUG% curl -G "https://sqlchoice.blob.core.windows.net/sqlchoice/static/tpcxbb_1gb.bak" -o tpcxbb_1gb.bak
)

for /F "usebackq tokens=1,2" %%v in (`sqlcmd -I -b -h-1 -W -Q "SET NOCOUNT ON; SELECT @@SERVERNAME, SERVERPROPERTY('IsHadrEnabled');"`) do (
	SET MASTER_POD_NAME=%%v
	SET HADR_ENABLED=%%w
)
if NOT DEFINED MASTER_POD_NAME goto exit

REM Copy the backup file, restore the database, create necessary objects and data file
echo Copying sales database backup file to SQL Master instance...
%DEBUG% kubectl cp tpcxbb_1gb.bak %CLUSTER_NAMESPACE%/%MASTER_POD_NAME%:var/opt/mssql/data/ -c mssql-server || goto exit

REM Download and copy the sample backup files
if /i "%AW_WWI_SAMPLES%" EQU "--install-extra-samples" (
    set FILES=AdventureWorks2016_EXT.bak AdventureWorksDW2016_EXT.bak
    for %%f in (!FILES!) do (
        if NOT EXIST %%f (
                echo Downloading %%f sample database backup file...
                %DEBUG% curl -L -G "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/%%f" -o %%f
        )
        echo Copying %%f database backup file to SQL Master instance...
        %DEBUG% kubectl cp %%f %CLUSTER_NAMESPACE%/%MASTER_POD_NAME%:var/opt/mssql/data/ -c mssql-server || goto exit

        echo Removing database backup file...
        %DEBUG% kubectl exec %MASTER_POD_NAME% -n %CLUSTER_NAMESPACE% -c mssql-server -i -t -- bash -c "rm -rvf /var/opt/mssql/data/%%f"
    )

    set FILES=WideWorldImporters-Full.bak WideWorldImportersDW-Full.bak
    for %%f in (!FILES!) do (
        if NOT EXIST %%f (
            echo Downloading %%f sample database backup file...
            %DEBUG% curl -L -G "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/%%f" -o %%f
        )
        echo Copying %%f database backup file to SQL Master instance...
        %DEBUG% kubectl cp %%f %CLUSTER_NAMESPACE%/%MASTER_POD_NAME%:var/opt/mssql/data/ -c mssql-server || goto exit

        echo Removing database backup file...
        %DEBUG% kubectl exec %MASTER_POD_NAME% -n %CLUSTER_NAMESPACE% -c mssql-server -i -t -- bash -c "rm -rvf /var/opt/mssql/data/%%f"
    )
)

REM If HADR is enabled then port-forward 1533 temporarily to connect to the primary directly
REM Default timeout for port-forward is 5 minutes so start command in background & it will terminate automatically
if /i "%HADR_ENABLED%" EQU "1" (
    %DEBUG% start "bootstrap-kubectl" kubectl port-forward svc/master-svc 1533:1533 -n %CLUSTER_NAMESPACE%
    SET SQLCMDSERVER=127.0.0.1,1533
)

echo Configuring sample database(s)...
%DEBUG% sqlcmd -i "%STARTUP_PATH%bootstrap-sample-db.sql" -o "bootstrap.out" -I -b || goto exit

REM remove files copied into the pod:
echo Removing database backup file...
%DEBUG% kubectl exec %MASTER_POD_NAME% -n %CLUSTER_NAMESPACE% -c mssql-server -i -t -- bash -c "rm -rvf /var/opt/mssql/data/tpcxbb_1gb.bak"

for %%F in (web_clickstreams inventory customer) do (
    if NOT EXIST %%F.csv (
        echo Exporting %%F data...
        if /i %%F EQU web_clickstreams (set DELIMITER=,) else (SET DELIMITER=^|)
        %DEBUG% bcp sales.dbo.%%F out "%%F.csv" -S %SQLCMDSERVER% %BCP_CREDENTIALS% -c -t"!DELIMITER!" -o "%%F.out" -e "%%F.err" || goto exit
    )
)

if NOT EXIST product_reviews.csv (
    echo Exporting product_reviews data...
    %DEBUG% bcp "select pr_review_sk, replace(replace(pr_review_content, ',', ';'), char(34), '') as pr_review_content from sales.dbo.product_reviews" queryout "product_reviews.csv" -S %SQLCMDSERVER% %BCP_CREDENTIALS% -c -t, -o "product_reviews.out" -e "product_reviews.err" || goto exit
)

REM Kill kubectl process if started
taskkill /F /T /FI "WINDOWTITLE EQ bootstrap-kubectl" /IM kubectl.exe >NUL 2>NUL

REM Copy the data file to HDFS
echo Uploading web_clickstreams data to HDFS...
if DEFINED KNOX_PASSWORD (
    %DEBUG% curl -s -S -L -k -u root:%KNOX_PASSWORD% -X PUT "https://%KNOX_ENDPOINT%/gateway/default/webhdfs/v1/clickstream_data?op=MKDIRS" || goto exit
    %DEBUG% curl -s -S -L -k -u root:%KNOX_PASSWORD% -X PUT "https://%KNOX_ENDPOINT%/gateway/default/webhdfs/v1/clickstream_data/web_clickstreams.csv?op=create&overwrite=true" -H "Content-Type: application/octet-stream" -T "web_clickstreams.csv" || goto exit
) else (
    %DEBUG% curl -s -S -L -k -u : --negotiate -X PUT "https://%KNOX_ENDPOINT%/gateway/default/webhdfs/v1/clickstream_data?op=MKDIRS" || goto exit
    %DEBUG% curl -s -S -L -k -u : --negotiate -X PUT "https://%KNOX_ENDPOINT%/gateway/default/webhdfs/v1/clickstream_data/web_clickstreams.csv?op=create&overwrite=true" -H "Content-Type: application/octet-stream" -T "web_clickstreams.csv" || goto exit
)
:: del /q web_clickstreams.*

echo.
echo Uploading product_reviews data to HDFS...
if DEFINED KNOX_PASSWORD (
    %DEBUG% curl -s -S -L -k -u root:%KNOX_PASSWORD% -X PUT "https://%KNOX_ENDPOINT%/gateway/default/webhdfs/v1/product_review_data?op=MKDIRS" || goto exit
    %DEBUG% curl -s -S -L -k -u root:%KNOX_PASSWORD% -X PUT "https://%KNOX_ENDPOINT%/gateway/default/webhdfs/v1/product_review_data/product_reviews.csv?op=create&overwrite=true" -H "Content-Type: application/octet-stream" -T "product_reviews.csv" || goto exit
) else (
    %DEBUG% curl -s -S -L -k -u : --negotiate -X PUT "https://%KNOX_ENDPOINT%/gateway/default/webhdfs/v1/product_review_data?op=MKDIRS" || goto exit
    %DEBUG% curl -s -S -L -k -u : --negotiate -X PUT "https://%KNOX_ENDPOINT%/gateway/default/webhdfs/v1/product_review_data/product_reviews.csv?op=create&overwrite=true" -H "Content-Type: application/octet-stream" -T "product_reviews.csv" || goto exit
)
:: del /q product_reviews.*

REM %DEBUG% del /q *.out *.err *.csv
echo .
echo Bootstrap of the sample database completed successfully.
echo Data files for Oracle setup are located at [%TMP%\%TMP_DIR_NAME%].

popd
endlocal
exit /b 0
goto :eof

:exit
    REM Kill kubectl process if started
    taskkill /F /T /FI "WINDOWTITLE EQ bootstrap-kubectl" /IM kubectl.exe >NUL 2>NUL
    echo Bootstrap of the sample database failed.
    echo Output and error files are in directory [%TMP%\%TMP_DIR_NAME%].
    exit /b 1

:usage
    echo USAGE: %0 ^<CLUSTER_NAMESPACE^> ^<SQL_MASTER_ENDPOINT^> ^<KNOX_ENDPOINT^> [--install-extra-samples] [SQL_MASTER_PORT] [KNOX_PORT]
    echo To use basic authentication please set AZDATA_USERNAME and AZDATA_PASSWORD environment variables.
    echo To use integrated authentication provide the DNS names for the endpoints.
    echo Port can be specified separately if using non-default values."
    exit /b 0
