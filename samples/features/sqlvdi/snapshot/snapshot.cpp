/***********************************************************************
Copyright (c) Microsoft Corporation
All Rights Reserved.
***********************************************************************/
// This source code is an intended supplement to the Microsoft SQL
// Server online references and related electronic documentation.
//
// This sample is for instructional purposes only.
// Code contained herein is not intended to be used "as is" in real applications.
// 
// snapshot.cpp
//
// This sample extends the "osimple.cpp" sample to demonstrate BACKUP WITH SNAPSHOT.
// It is not fully functional.  The ability to take/mount snapshots must be provided.
//
// This is a sample program used to demonstrate the Virtual Device Interface
// feature of Microsoft SQL Server together with an ODBC connection.
//
// The program will request backup or restore of a single database
// on some instance of sql server.
//
// The program accepts input:
//    {b | r} <databaseName> [<instanceName>]
//  b -> backup
//  r -> restore
//


// To gain access to free threaded COM, you'll need to define _WIN32_DCOM
// before the system headers, either in the source (as in this example),
// or when invoking the compiler (by using /D "_WIN32_DCOM")
//
// This sample uses Windows NT Authentication, other than mixed mode security, 
// to establish connections. If you want to use mixed mode security, please 
// set Trusted_Connection to no in the SQLDriverConnect command. 
// Make necessary change to the server name in the SQLDriverConnect command.
//
#define _WIN32_DCOM

#include <objbase.h>    // for 'CoInitialize()'
#include <stdio.h>      // for file operations
#include <ctype.h>      // for toupper ()
#include <process.h>    // for C library-safe _beginthreadex,_endthreadex

#include "vdi.h"        // interface declaration
#include "vdierror.h"   // error constants

#include "vdiguid.h"    // define the interface identifiers.
                        // IMPORTANT: vdiguid.h can only be included in one source file.
                        // 

#include <windows.h>
#include "sql.h"
#include "sqlext.h"
#include "odbcss.h"

void performTransfer(
    IClientVirtualDeviceSet2*      vds,
    IClientVirtualDevice*          vd,
    int                            backup);

HANDLE execSQL(bool doBackup, WCHAR* pInstanceName, WCHAR* pDbName, WCHAR* pVdsName);
bool checkSQL(HANDLE);

bool ynPrompt(const char* str);

//------------------------------------------------------------
//
// Mainline
//
int __cdecl
main(int argc, char* argv[])
{
    HRESULT                     hr;
    IClientVirtualDeviceSet2*   vds = nullptr;
    IClientVirtualDevice*       vd = nullptr;

    VDConfig                    config;
    bool                        badParm = true;
    bool                        doBackup;
    HANDLE                      hThread = nullptr;
    char*                       pDbName = nullptr;
    char*                       pInstanceName = nullptr;
    WCHAR                       wInstanceName[128] = { 0 };
    int                         rc = 0;

    // Check the input parm
    //
    if (argc >= 3)
    {
        char param = toupper(argv[1][0]);

        if (param == 'B')
        {
            doBackup = true;
            badParm = false;
        }
        else if (param == 'R')
        {
            doBackup = false;
            badParm = false;
        }

        pDbName = argv[2];

        if (argc == 4)
        {
            pInstanceName = argv[3];
        }
    }

    if (badParm)
    {
        printf("usage: snapshot {B|R} <databaseName> [<instanceName>]\n"
            "Demonstrate a Backup or Restore WITH SNAPSHOT\n");
        printf("\n\n** NOTE **\n The ability to take or mount snapshots must be implemented\n"
            "before this sample is truely functional.\n");
        exit(1);
    }

    printf("Performing a %s of %s on %s using a VIRTUAL_DEVICE.\n",
        (doBackup) ? "BACKUP" : "RESTORE",
        pDbName,
        (pInstanceName) ? pInstanceName : "Default");

    // Initialize COM Library
    // Note: _WIN32_DCOM must be defined during the compile.
    //
    hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);

    if (FAILED(hr))
    {
        printf("Coinit fails: x%X\n", hr);
        exit(1);
    }

    // Get an interface to the device set.
    // Notice how we use a single IID for both the class and interface
    // identifiers.
    //
    hr = CoCreateInstance(
        CLSID_MSSQL_ClientVirtualDeviceSet,
        nullptr,
        CLSCTX_INPROC_SERVER,
        IID_IClientVirtualDeviceSet2,
        (void**)&vds);

    if (FAILED(hr))
    {
        // This failure might happen if the DLL was not registered,
        // or if the application is using the wrong interface id (IID).
        //
        printf("Could not create component: x%X\n", hr);
        printf("Check registration of SQLVDI.DLL and value of IID\n");
        goto exit;
    }

    // Setup the VDI configuration we want to use.
    // This program doesn't use any fancy features, so the
    // only field to setup is the deviceCount.
    //
    // The server will treat the virtual device just like a pipe:
    // I/O will be strictly sequential with only the basic commands.
    //
    memset(&config, 0, sizeof(config));
    config.deviceCount = 1;
    config.features = VDF_SnapshotPrepare;

    // Create a GUID to use for a unique virtual device name
    //
    GUID     vdsId;
    WCHAR    wVdsName[50];
    CoCreateGuid(&vdsId);
    StringFromGUID2(vdsId, wVdsName, 49);

    // Create the virtual device set
    // Notice that we only support unicode interfaces
    //

    if (pInstanceName)
    {
        rc = MultiByteToWideChar(CP_ACP, 0,
            pInstanceName, strlen(pInstanceName),
            wInstanceName, 127);
    }
    wInstanceName[rc] = 0;

    hr = vds->CreateEx(wInstanceName, wVdsName, &config);
    if (FAILED(hr))
    {
        printf("VDS::Create fails: x%X", hr);
        goto exit;
    }

    // Send the SQL command, by starting a thread to handle the ODBC
    //
    printf("\nSending the SQL...\n");

    WCHAR wDbName[128];
    MultiByteToWideChar(CP_ACP, 0,
        pDbName, -1,
        wDbName, 127);

    hThread = execSQL(doBackup, wInstanceName, wDbName, wVdsName);
    if (hThread == nullptr)
    {
        printf("execSQL failed.\n");
        goto shutdown;
    }

    // Wait for the server to connect, completing the configuration.
    //
    printf("\nWaiting for SQLServer to respond...\n");

    while (FAILED(hr = vds->GetConfiguration(1000, &config)))
    {
        if (hr == VD_E_TIMEOUT)
        {
            // Check on the SQL thread
            //
            DWORD rc = WaitForSingleObject(hThread, 1000);
            if (rc == WAIT_OBJECT_0)
            {
                printf("SQL command failed before VD transfer\n");
                goto shutdown;
            }
            if (rc == WAIT_TIMEOUT)
            {
                continue;
            }
            printf("Check on SQL failed: %d\n", rc);
            goto shutdown;
        }

        printf("VDS::Getconfig fails: x%X\n", hr);
        goto shutdown;
    }

    // Open the single device in the set.
    //
    hr = vds->OpenDevice(wVdsName, &vd);
    if (FAILED(hr))
    {
        printf("VDS::OpenDevice fails: x%X\n", hr);
        goto shutdown;
    }

    printf("\nPerforming data transfer...\n");

    performTransfer(vds, vd, doBackup);


shutdown:

    // Close the set
    //
    vds->Close();

    // Obtain the SQL completion information
    //
    if (hThread != nullptr)
    {
        if (checkSQL(hThread))
            printf("\nThe SQL command executed successfully.\n");
        else
            printf("\nThe SQL command failed.\n");

        CloseHandle(hThread);
    }

    // COM reference counting: Release the interface.
    //
    vds->Release();

exit:
    // Uninitialize COM Library
    //
    CoUninitialize();

    return 0;
}

//---------------------------------------------------------------------------
// ODBC Message processing routine.
// This is SQLServer specific, to show native message IDs, sev, state.
//
// The routine will watch for message 3014 in order to detect
// a successful backup/restore operation.  This is useful for
// operations like RESTORE which can sometimes recover from
// errors (error messages will be followed by the 3014 success message).
//
void ProcessMessages(
    SQLSMALLINT      handle_type,    // ODBC handle type
    SQLHANDLE        handle,         // ODBC handle
    bool             ConnInd,        // TRUE if sucessful connection made
    bool*            pBackupSuccess) // Set TRUE if a 3014 message is seen.
{
    RETCODE                plm_retcode = SQL_SUCCESS;
    SQLWCHAR               plm_szSqlState[SQL_SQLSTATE_SIZE + 1];
    SQLWCHAR               plm_szErrorMsg[SQL_MAX_MESSAGE_LENGTH + 1];
    SDWORD                 plm_pfNativeError = 0L;
    SWORD                  plm_pcbErrorMsg = 0;
    SQLSMALLINT            plm_cRecNmbr = 1;
    SDWORD                 plm_SS_MsgState = 0, plm_SS_Severity = 0;
    SQLBIGINT              plm_Rownumber = 0;
    USHORT                 plm_SS_Line;
    SQLSMALLINT            plm_cbSS_Procname, plm_cbSS_Srvname;
    SQLCHAR                plm_SS_Procname[MAXNAME], plm_SS_Srvname[MAXNAME];

    while (plm_retcode != SQL_NO_DATA_FOUND)
    {
        plm_retcode = SQLGetDiagRec(handle_type, handle,
            plm_cRecNmbr, plm_szSqlState, &plm_pfNativeError,
            plm_szErrorMsg, SQL_MAX_MESSAGE_LENGTH, &plm_pcbErrorMsg);

        // Note that if the application has not yet made a
        // successful connection, the SQLGetDiagField
        // information has not yet been cached by ODBC
        // Driver Manager and these calls to SQLGetDiagField
        // will fail.
        //
        if (plm_retcode != SQL_NO_DATA_FOUND)
        {
            if (ConnInd)
            {
                plm_retcode = SQLGetDiagField(
                    handle_type, handle, plm_cRecNmbr,
                    SQL_DIAG_ROW_NUMBER, &plm_Rownumber,
                    SQL_IS_INTEGER,
                    NULL);

                plm_retcode = SQLGetDiagField(
                    handle_type, handle, plm_cRecNmbr,
                    SQL_DIAG_SS_LINE, &plm_SS_Line,
                    SQL_IS_INTEGER,
                    NULL);

                plm_retcode = SQLGetDiagField(
                    handle_type, handle, plm_cRecNmbr,
                    SQL_DIAG_SS_MSGSTATE, &plm_SS_MsgState,
                    SQL_IS_INTEGER,
                    NULL);

                plm_retcode = SQLGetDiagField(
                    handle_type, handle, plm_cRecNmbr,
                    SQL_DIAG_SS_SEVERITY, &plm_SS_Severity,
                    SQL_IS_INTEGER,
                    NULL);

                plm_retcode = SQLGetDiagField(
                    handle_type, handle, plm_cRecNmbr,
                    SQL_DIAG_SS_PROCNAME, &plm_SS_Procname,
                    sizeof(plm_SS_Procname),
                    &plm_cbSS_Procname);

                plm_retcode = SQLGetDiagField(
                    handle_type, handle, plm_cRecNmbr,
                    SQL_DIAG_SS_SRVNAME, &plm_SS_Srvname,
                    sizeof(plm_SS_Srvname),
                    &plm_cbSS_Srvname);

                printf_s("Msg %ld, SevLevel %ld, State %ld, SQLState %ls\n",
                    plm_pfNativeError,
                    plm_SS_Severity,
                    plm_SS_MsgState,
                    plm_szSqlState);
            }

            printf("%ls\n", plm_szErrorMsg);

            if (pBackupSuccess && plm_pfNativeError == 3014)
            {
                *pBackupSuccess = TRUE;
            }
        }

        plm_cRecNmbr++; //Increment to next diagnostic record.
    } // End while.
}



//------------------------------------------------------------------
// The mainline of the ODBC thread.
//
// Returns TRUE if a successful backup/restore is performed.
//
struct PARMS
{
    bool      doBackup;
    WCHAR*    pInstanceName;
    WCHAR*    pDbName;
    WCHAR*    pVdsName;
};

unsigned __stdcall
SQLRoutine(void* input)
{
    PARMS* parms = (PARMS*)input;

    SQLWCHAR*   pSQLText;       // the command being executed.
    bool        successDetected = false;

    // ODBC handles
    //
    SQLHENV     henv = nullptr;
    SQLHDBC     hdbc = nullptr;
    SQLHSTMT    hstmt = nullptr;

    WCHAR       sqlCommand[1024];
    SQLWCHAR    connectString[200] = { 0 };

    bool        sentSQL = false;
    int         rc;

    #define     MAX_CONN_OUT 1024
    SQLWCHAR    szOutConn[MAX_CONN_OUT] = { 0 };
    SQLSMALLINT cbOutConn;


    // Generate the command to execute
    //
    swprintf_s(sqlCommand, L"%ls DATABASE [%ls] %ls VIRTUAL_DEVICE='%ls' WITH SNAPSHOT",
        parms->doBackup ? L"BACKUP" : L"RESTORE",
        parms->pDbName,
        parms->doBackup ? L"TO" : L"FROM",
        parms->pVdsName);

    // Initialize the ODBC environment.
    //
    if (SQLAllocHandle(SQL_HANDLE_ENV, NULL, &henv) == SQL_ERROR)
        goto exit;

    // This is an ODBC v3 application
    //
    SQLSetEnvAttr(henv, SQL_ATTR_ODBC_VERSION, (void*)SQL_OV_ODBC3, SQL_IS_INTEGER);

    // Allocate a connection handle
    //
    if (SQLAllocHandle(SQL_HANDLE_DBC, henv, &hdbc) == SQL_ERROR)
    {
        printf("AllocHandle on DBC failed.");
        goto exit;
    }

    wcscpy_s(connectString, 200, L"DRIVER={SQL Server};Trusted_Connection=yes;SERVER=.");
    if (parms->pInstanceName)
    {
        swprintf_s(connectString + wcslen(connectString), 200 - wcslen(connectString), L"\\%ls", parms->pInstanceName);
    }

    printf("\n\nConnecting with: %ls\n", connectString);

    // Connect to the server using Trusted connection.
    // Trusted connection uses integrated NT security.
      // If you want to use mixed-mode Authentication, please set Trusted_Connection to no.
    rc = SQLDriverConnect(
        hdbc,
        nullptr,   // no diaglogs please
        connectString,
        SQL_NTS,
        szOutConn,
        MAX_CONN_OUT,
        &cbOutConn,
        SQL_DRIVER_NOPROMPT);

    if (rc == SQL_ERROR)
    {
        SQLWCHAR        szSqlState[20];
        SQLINTEGER      ssErr;
        SQLWCHAR        szErrorMsg[MAX_CONN_OUT];
        SQLSMALLINT     cbErrorMsg;

        printf("Connect fails\n");

        rc = SQLError(
            henv, hdbc, SQL_NULL_HSTMT,
            szSqlState,
            &ssErr,
            szErrorMsg,
            MAX_CONN_OUT,
            &cbErrorMsg);

        printf("msg=%ls\n", szErrorMsg);

        goto exit;
    }

    // Get a statement handle
    //
    if (SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt) == SQL_ERROR)
    {
        printf("Failed to get statement handle\n");

        ProcessMessages(SQL_HANDLE_DBC, hdbc, true, nullptr);
        goto exit;
    }

    // Execute the SQL
    //
    printf("\n\nExecuting SQL: %ls\n", sqlCommand);

    pSQLText = sqlCommand;

    rc = SQLExecDirect(hstmt, pSQLText, SQL_NTS);

    // Extract all the resulting messages
    //

    SQLSMALLINT numResultCols;
    while (1)
    {
        switch (rc)
        {
        case SQL_ERROR:
            successDetected = false;
            ProcessMessages(SQL_HANDLE_STMT, hstmt, true, &successDetected);
            if (!successDetected)
            {
                printf("Errors resulted in failure of the command\n");
                goto exit;
            }
            printf("Errors were encountered but the command was able to recover and successfully complete.\n");
            break;

        case SQL_SUCCESS_WITH_INFO:
            ProcessMessages(SQL_HANDLE_STMT, hstmt, TRUE, NULL);
            // fall through

        case SQL_SUCCESS:
            successDetected = true;

            numResultCols = 0;
            SQLNumResultCols(hstmt, &numResultCols);
            if (numResultCols > 0)
            {
                printf("A result set with %d columns was produced\n",
                    (int)numResultCols);
            }
            break;

        case SQL_NO_DATA:
            // All results have been processed.  We are done.
            //
            goto exit;

        case SQL_NEED_DATA:
        case SQL_INVALID_HANDLE:
        case SQL_STILL_EXECUTING:
        default:
            successDetected = false;
            printf("Unexpected SQLExec result %d\n", rc);
            goto exit;
        }
        rc = SQLMoreResults(hstmt);
    }

exit:
    // Release the ODBC resources.
    //
    if (hstmt != nullptr)
    {
        SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
        hstmt = nullptr;
    }

    if (hdbc != nullptr)
    {
        SQLDisconnect(hdbc);
        SQLFreeHandle(SQL_HANDLE_DBC, hdbc);
        hdbc = nullptr;
    }

    if (henv != nullptr)
    {
        SQLFreeHandle(SQL_HANDLE_ENV, henv);
        henv = nullptr;
    }

    return successDetected;
}


//------------------------------------------------------------
//
// execSQL: Send the SQL to the server via ODBC.
//
// Return the thread handle (NULL on error).
//
HANDLE execSQL(bool doBackup, WCHAR* pInstanceName, WCHAR* pDbName, WCHAR* pVDName)
{
    unsigned int    threadId;
    HANDLE          hThread;
    static PARMS    parms; // yucky, but only a single command is used....

    parms.doBackup = doBackup;
    parms.pDbName = pDbName;
    parms.pInstanceName = pInstanceName;
    parms.pVdsName = pVDName;

    hThread = (HANDLE)_beginthreadex(
        nullptr, 0, SQLRoutine, (void*)&parms, 0, &threadId);
    if (hThread == nullptr)
    {
        printf("Failed to create thread. errno is %d\n", errno);
    }
    return hThread;
}

//------------------------------------------------------------
//
// checkSQL: Wait for the T-SQL to complete, 
//    returns TRUE if statement successfully executed.
//
bool checkSQL(HANDLE hThread)
{
    if (hThread == nullptr)
        return false;

    DWORD    rc = WaitForSingleObject(hThread, INFINITE);
    if (rc != WAIT_OBJECT_0)
    {
        printf("checkSQL failed: %d\n", rc);
        return false;
    }
    if (!GetExitCodeThread(hThread, &rc))
    {
        printf("failed to get exit code: %d\n", GetLastError());
        return false;
    }
    return rc == true;
}


//----------------------------------------------------------------------------------
// Ask the user a "yes/no" question.
// Return TRUE if he answers "yes"
//
bool ynPrompt(const char* str)
{
    char line[256];

    printf("\n\n%s\n", str);
    fgets(line, sizeof(line), stdin);

    // Remove newline character if fgets reads in a newline.
    size_t len = strlen(line);
    if (len > 0 && line[len - 1] == '\n') {
        line[len - 1] = '\0';
    }

    return (line[0] == 'y' || line[0] == 'Y');
}

//----------------------------------------------------------------------------------
// VDI data transfer handler.
//
// This routine reads commands from the server until a 'Close' status is received.
// It simply reads or writes a file 'superbak.dmp' in the current directory.
//
void performTransfer(
    IClientVirtualDeviceSet2*    iVds,
    IClientVirtualDevice*        vd,
    int                          backup)
{
    FILE*           fh;
    char*           fname = (char*)"snapshot.dmp";
    VDC_Command*    cmd;
    DWORD           completionCode;
    DWORD           bytesTransferred;
    HRESULT         hr;

    errno_t error = fopen_s(&fh, fname, (backup) ? "wb" : "rb");
    if (error != 0)
    {
        printf("Failed to open: %s\n", fname);
        return;
    }

    while (SUCCEEDED(hr = vd->GetCommand(INFINITE, &cmd)))
    {
        bytesTransferred = 0;
        switch (cmd->commandCode)
        {
        case VDC_Read:
            bytesTransferred = fread(cmd->buffer, 1, cmd->size, fh);
            if (bytesTransferred == cmd->size)
                completionCode = ERROR_SUCCESS;
            else
                // assume failure is eof
                completionCode = ERROR_HANDLE_EOF;
            break;

        case VDC_Write:
            bytesTransferred = fwrite(cmd->buffer, 1, cmd->size, fh);
            if (bytesTransferred == cmd->size)
            {
                completionCode = ERROR_SUCCESS;
            }
            else
                // assume failure is disk full
                completionCode = ERROR_DISK_FULL;
            break;

        case VDC_Flush:
            fflush(fh);
            completionCode = ERROR_SUCCESS;
            break;

        case VDC_ClearError:
            completionCode = ERROR_SUCCESS;
            break;

        case VDC_PrepareToFreeze:
            printf("\n*** SQL Server is prepared to freeze the database now ***\n");
            printf("At this point the application can perform any final coordination activities.\n");

            while (!ynPrompt("Are you ready to freeze the database?"))
            {
                if (ynPrompt("Do you want to abort?"))
                {
                    iVds->SignalAbort();
                    return;
                }
            }
            // Acknowledging this command results in a freeze of database writes.
            // The server will then issue VDC_Write commands to record metadata
            // about the frozen state.
            // Then the VDC_Snapshot is issued.
            //
            completionCode = ERROR_SUCCESS;
            break;

        case VDC_Snapshot:
            // At this point the metadata is complete, so the
            // output stream can be closed.  Thus it is possible
            // to include the metadata with the data of the snapshot.
            //
            fclose(fh);
            fh = nullptr;

            printf("\n*** Make the snapshot now ***\n");

            while (!ynPrompt("Did you complete the snapshot?"))
            {
                if (ynPrompt("Do you want to abort?"))
                {
                    iVds->SignalAbort();
                    return;
                }
            }

            // For clarity, we "unroll" the loop logic
            // in the following block of code so you can
            // easily see the sequence of operations.
            //

            // Tell SQLServer that the snapshot is done.
            //
            completionCode = ERROR_SUCCESS;
            hr = vd->CompleteCommand(cmd, completionCode, bytesTransferred, 0);
            if (FAILED(hr))
            {
                printf("Completion Failed: x%X\n", hr);
                return;
            }

            // The only valid command will be a "close" request.
            //
            hr = vd->GetCommand(INFINITE, &cmd);
            if (hr != VD_E_CLOSE)
            {
                printf("Unexpected snapshot termination: x%X\n", hr);
            }
            else
            {
                printf("SQLServer is aware that the snapshot is successful.\n");
            }
            return;

        case VDC_MountSnapshot:
            printf("\n*** Mount the snapshot now ***\n");

            while (!ynPrompt("Did you complete the snapshot?"))
            {
                if (ynPrompt("Do you want to abort?"))
                {
                    iVds->SignalAbort();
                    return;
                }
            }
            completionCode = ERROR_SUCCESS;
            break;

        default:
            // If command is unknown...
            completionCode = ERROR_NOT_SUPPORTED;
        }

        hr = vd->CompleteCommand(cmd, completionCode, bytesTransferred, 0);
        if (FAILED(hr))
        {
            printf("Completion Failed: x%X\n", hr);
            break;
        }
    }

    if (hr != VD_E_CLOSE)
    {
        printf("Unexpected termination: x%X\n", hr);
    }
    else
    {
        // As far as the data transfer is concerned, no
        // errors occurred.  The code which issues the SQL
        // must determine if the backup/restore was
        // really successful.
        //
        printf("Successfully completed data transfer.\n");
    }

    if (fh != nullptr)
    {
        fclose(fh);
    }
}


