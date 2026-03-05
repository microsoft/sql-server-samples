#!/bin/bash
set -e
set -o pipefail

STARTUP_PATH=$(pwd)
TMP_DIR_NAME=$(basename $0)
USAGE_MESSAGE="USAGE: $0 <CLUSTER_NAMESPACE> <SQL_MASTER_ENDPOINT> <KNOX_ENDPOINT> [--install-extra-samples] [SQL_MASTER_PORT] [KNOX_PORT]
To use basic authentication please set AZDATA_USERNAME and AZDATA_PASSWORD environment variables.
To use integrated authentication provide the DNS names for the endpoints.
Port can be specified separately if using non-default values."
ERROR_MESSAGE="Bootstrap of the sample database failed. Output and error files are in directory [/tmp/$TMP_DIR_NAME]."

# Print usage if mandatory parameters are missing
: "${1:?$USAGE_MESSAGE}"
: "${2:?$USAGE_MESSAGE}"
: "${3:?$USAGE_MESSAGE}"
: "${DEBUG=}"

# Save the input parameters
CLUSTER_NAMESPACE=$1
SQL_MASTER_ENDPOINT=$2
KNOX_ENDPOINT=$3
AW_WWI_SAMPLES=$4
SQL_MASTER_PORT=$5
KNOX_PORT=$6

# Skip if extra samples doesn't need to be installed
AW_WWI_SAMPLES=${AW_WWI_SAMPLES:=no}

# Use default ports if not specified
SQL_MASTER_PORT=${SQL_MASTER_PORT:=31433}
KNOX_PORT=${KNOX_PORT:=30443}
SQL_MASTER_INSTANCE=$SQL_MASTER_ENDPOINT,$SQL_MASTER_PORT
KNOX_ENDPOINT=$KNOX_ENDPOINT:$KNOX_PORT

# Set username/password variables
export SQLCMDSERVER=$SQL_MASTER_INSTANCE
export SQLCMDUSER=$AZDATA_USERNAME
export SQLCMDPASSWORD=$AZDATA_PASSWORD
KNOX_PASSWORD=$AZDATA_PASSWORD

if [ -z SQLCMDUSER ]
then
    BCP_CREDENTIALS="-T"
else
    BCP_CREDENTIALS="-U$SQLCMDUSER -P$SQLCMDPASSWORD"
fi

for util in sqlcmd bcp kubectl curl
    do
    echo Verifying $util is in path & which $util 1>/dev/null 2>/dev/null || (echo Unable to locate $util && exit 1)
done

# Copy the backup file, restore the database, create necessary objects and data file
pushd "/tmp" > /dev/null
$DEBUG mkdir -p "$TMP_DIR_NAME"
$DEBUG cd "$TMP_DIR_NAME"

if [ ! -f tpcxbb_1gb.bak ]
then
    echo Downloading sample database backup file...
    $DEBUG curl -G "https://sqlchoice.blob.core.windows.net/sqlchoice/static/tpcxbb_1gb.bak" -o tpcxbb_1gb.bak
fi

read -r MASTER_POD_NAME HADR_ENABLED <<<$(sqlcmd -I -b -h-1 -W -Q "SET NOCOUNT ON; SELECT @@SERVERNAME, SERVERPROPERTY('IsHadrEnabled');")
if [ -z $MASTER_POD_NAME ]
then
    echo $ERROR_MESSAGE
    exit 1
fi

echo Copying sales database backup file...
$DEBUG kubectl cp tpcxbb_1gb.bak $CLUSTER_NAMESPACE/$MASTER_POD_NAME:var/opt/mssql/data -c mssql-server || (echo $ERROR_MESSAGE && exit 1)

if [ "$AW_WWI_SAMPLES" == "--install-extra-samples" ]
then
    for file in AdventureWorks2016_EXT.bak AdventureWorksDW2016_EXT.bak
    do
        if [ ! -f $file ]
        then
            echo Downloading $file sample database backup file...
            $DEBUG curl -L -G "https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/$file" -o $file
        fi
        echo Copying $file database backup file to SQL Master instance...
        $DEBUG kubectl cp $file $CLUSTER_NAMESPACE/$MASTER_POD_NAME:var/opt/mssql/data -c mssql-server || (echo $ERROR_MESSAGE && exit 1)
    done


    for file in WideWorldImporters-Full.bak WideWorldImportersDW-Full.bak
    do
        if [ ! -f $file ]
        then
            echo Downloading $file sample database backup file...
            $DEBUG curl -L -G "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/$file" -o $file
        fi
        echo Copying $file database backup file to SQL Master instance...
        $DEBUG kubectl cp $file $CLUSTER_NAMESPACE/$MASTER_POD_NAME:var/opt/mssql/data -c mssql-server || (echo $ERROR_MESSAGE && exit 1)
    done
fi

# If HADR is enabled then port-forward 1533 temporarily to connect to the primary directly
# Default timeout for port-forward is 5 minutes so start command in background & it will terminate automatically
if [ "$HADR_ENABLED" == "1" ]
then
    $DEBUG kubectl port-forward pods/$MASTER_POD_NAME 1533:1533 -n $CLUSTER_NAMESPACE &
    PROC_ID=$!
    SQLCMDSERVER=127.0.0.1,1533
fi

echo Configuring sample database...
$DEBUG sqlcmd -I -b -i "$STARTUP_PATH/bootstrap-sample-db.sql" -o "bootstrap.out" || (echo $ERROR_MESSAGE && kill -9 $PROC_ID > /dev/null && exit 2)

# remove files copied into the pod:
echo "Removing database backup file(s)..."
$DEBUG kubectl exec $MASTER_POD_NAME -n $CLUSTER_NAMESPACE -c mssql-server -i -t -- bash -c "rm -rvf /var/opt/mssql/data/tpcxbb_1gb.bak"

if [ "$AW_WWI_SAMPLES" == "--install-extra-samples" ]
then
    for file in AdventureWorks2016_EXT.bak AdventureWorksDW2016_EXT.bak
    do
        $DEBUG kubectl exec $MASTER_POD_NAME -n $CLUSTER_NAMESPACE -c mssql-server -i -t -- bash -c "rm -rvf /var/opt/mssql/data/$file"
    done

    for file in WideWorldImporters-Full.bak WideWorldImportersDW-Full.bak
    do
        $DEBUG kubectl exec $MASTER_POD_NAME -n $CLUSTER_NAMESPACE -c mssql-server -i -t -- bash -c "rm -rvf /var/opt/mssql/data/$file"
    done
fi

for table in web_clickstreams inventory customer
    do
    echo Exporting $table data...
    if [ $table == web_clickstreams ]
    then 
        DELIMITER=,
    else
        DELIMITER="|"
    fi
    # WSL ex: "/mnt/c/Program Files/Microsoft SQL Server/Client SDK/ODBC/130/Tools/Binn/bcp.exe"
    if [ ! -f $table.csv ]
    then
        $DEBUG bcp sales.dbo.$table out "$table.csv" -S $SQLCMDSERVER $BCP_CREDENTIALS -c -t"$DELIMITER" -e "$table.err" > "$table.out" || (echo $ERROR_MESSAGE && kill -9 $PROC_ID > /dev/null && exit 3)
    fi
done

if [ ! -f product_reviews.csv ]
then
    echo Exporting product_reviews data...
    $DEBUG bcp "select pr_review_sk, replace(replace(pr_review_content, ',', ';'), char(34), '') as pr_review_content from sales.dbo.product_reviews" queryout "product_reviews.csv" -S $SQLCMDSERVER $BCP_CREDENTIALS -c -t, -e "product_reviews.err" > "$table.out" || (echo $ERROR_MESSAGE && kill -9 $PROC_ID > /dev/null && exit 3)
fi

if [[ $PROC_ID ]]
then
    kill -9 $PROC_ID > /dev/null
fi

# Copy the data file to HDFS
echo Uploading web_clickstreams data to HDFS...
if [[ $KNOX_PASSWORD ]]
then
    $DEBUG curl -s -S -L -k -u root:$KNOX_PASSWORD -X PUT "https://$KNOX_ENDPOINT/gateway/default/webhdfs/v1/clickstream_data?op=MKDIRS" 1>/dev/null || (echo $ERROR_MESSAGE && exit 4)
    $DEBUG curl -s -S -L -k -u root:$KNOX_PASSWORD -X PUT "https://$KNOX_ENDPOINT/gateway/default/webhdfs/v1/clickstream_data/web_clickstreams.csv?op=create&overwrite=true" -H 'Content-Type: application/octet-stream' -T "web_clickstreams.csv" 1>/dev/null || (echo $ERROR_MESSAGE && exit 5)
else
    $DEBUG curl -s -S -L -k -u : --negotiate -X PUT "https://$KNOX_ENDPOINT/gateway/default/webhdfs/v1/clickstream_data?op=MKDIRS" 1>/dev/null || (echo $ERROR_MESSAGE && exit 4)
    $DEBUG curl -s -S -L -k -u : --negotiate -X PUT "https://$KNOX_ENDPOINT/gateway/default/webhdfs/v1/clickstream_data/web_clickstreams.csv?op=create&overwrite=true" -H 'Content-Type: application/octet-stream' -T "web_clickstreams.csv" 1>/dev/null || (echo $ERROR_MESSAGE && exit 5)
fi
#$DEBUG rm -f web_clickstreams.*

echo Uploading product_reviews data to HDFS...
if [[ $KNOX_PASSWORD ]]
then
    $DEBUG curl -s -S -L -k -u root:$KNOX_PASSWORD -X PUT "https://$KNOX_ENDPOINT/gateway/default/webhdfs/v1/product_review_data?op=MKDIRS" 1>/dev/null || (echo $ERROR_MESSAGE && exit 6)
    $DEBUG curl -s -S -L -k -u root:$KNOX_PASSWORD -X PUT "https://$KNOX_ENDPOINT/gateway/default/webhdfs/v1/product_review_data/product_reviews.csv?op=create&overwrite=true" -H "Content-Type: application/octet-stream" -T "product_reviews.csv" 1>/dev/null || (echo $ERROR_MESSAGE && exit 7)
else
    $DEBUG curl -s -S -L -k -u : --negotiate -X PUT "https://$KNOX_ENDPOINT/gateway/default/webhdfs/v1/product_review_data?op=MKDIRS" 1>/dev/null || (echo $ERROR_MESSAGE && exit 6)
    $DEBUG curl -s -S -L -k -u : --negotiate -X PUT "https://$KNOX_ENDPOINT/gateway/default/webhdfs/v1/product_review_data/product_reviews.csv?op=create&overwrite=true" -H "Content-Type: application/octet-stream" -T "product_reviews.csv" 1>/dev/null || (echo $ERROR_MESSAGE && exit 7)
fi
#$DEBUG rm -f product_reviews.*

echo Bootstrap of the sample database completed successfully.
echo Data files for Oracle setup are located at [/tmp/$TMP_DIR_NAME].

# $DEBUG rm -f *.out *.err *.csv
popd
exit 0
