if ! systemctl is-active --quiet mssql-server.service; then dir

    echo "False"
    exit
    else
        echo "True"
    fi