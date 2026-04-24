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
// osimple.cpp
//
// This sample extends the "simple.cpp" sample to use an ODBC connection.
// This is intended only as an introduction to ODBC; not as a comprehensive tutorial.
//
// This is a sample program used to demonstrate the Virtual Device Interface
// feature of Microsoft SQL Server together with an ODBC connection.
//
// The program will backup or restore the 'pubs' sample database from
// the default instance of sql server.
//
// The program accepts a single command line parameter.  
// One of:
//  b   perform a backup
//  r   perform a restore
//  


// To gain access to free threaded COM, you'll need to define _WIN32_DCOM
// before the system headers, either in the source (as in this example),
// or when invoking the compiler (by using /D "_WIN32_DCOM")
//
// This sample uses Windows NT Authentication, other than mixed mode security, 
// to establish connections. If you want to use mixed mode security, please 
// set Trusted_Connection to no in the SQLDriverConnect command. 
// Make necessary change to the server name in the SQLDriverConnect command.

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
    IClientVirtualDevice*   vd,
    int                     backup);

HANDLE execSQL(bool doBackup);
bool checkSQL(HANDLE);

// Using a GUID for the VDS Name is a good way to assure uniqueness.
//
WCHAR    wVdsName[50];

//------------------------------------------------------------
//
// Mainline
//
int main(int argc, char* argv[])
{
    HRESULT                     hr;
    IClientVirtualDeviceSet2*   vds = nullptr;
    IClientVirtualDevice*       vd = nullptr;

    VDConfig                    config;
    bool                        badParm = true;
    bool                        doBackup;
    HANDLE                      hThread = nullptr;

    // Check the input parm
    //
    if (argc == 2)
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
    }

    if (badParm)
    {
        printf("usage: osimple {B|R}\n"
            "Demonstrate a Backup or Restore using the Virtual Device Interface & ODBC\n");
        exit(1);
    }

    printf("Performing a %s using a virtual device.\n",
        (doBackup) ? "BACKUP" : "RESTORE");

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

    // Create a GUID to use for a unique virtual device name
    //
    GUID    vdsId;
    CoCreateGuid(&vdsId);
    StringFromGUID2(vdsId, wVdsName, 49);

    // Create the virtual device set
    // for use by the default instance.
    // 
    // To use a named instance, change the 
    // first parameter in CreateEx to your instance's name.
    //
    hr = vds->CreateEx(nullptr, wVdsName, &config);
    if (FAILED(hr))
    {
        printf("VDS::Create fails: x%X", hr);
        goto exit;
    }

    // Send the SQL command, by starting a thread to handle the ODBC
    //
    printf("\nSending the SQL...\n");

    hThread = execSQL(doBackup);
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
            DWORD    rc = WaitForSingleObject(hThread, 1000);
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

    performTransfer(vd, doBackup);


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
    RETCODE             plm_retcode = SQL_SUCCESS;
    SQLWCHAR            plm_szSqlState[SQL_SQLSTATE_SIZE + 1];
    SQLWCHAR            plm_szErrorMsg[SQL_MAX_MESSAGE_LENGTH + 1];
    SDWORD              plm_pfNativeError = 0L;
    SWORD               plm_pcbErrorMsg = 0;
    SQLSMALLINT         plm_cRecNmbr = 1;
    SDWORD              plm_SS_MsgState = 0, plm_SS_Severity = 0;
    SQLBIGINT           plm_Rownumber = 0;
    USHORT              plm_SS_Line;
    SQLSMALLINT         plm_cbSS_Procname, plm_cbSS_Srvname;
    SQLWCHAR            plm_SS_Procname[MAXNAME], plm_SS_Srvname[MAXNAME];

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

                printf_s("Msg %d, SevLevel %d, State %d, SQLState %ls\n",
                    plm_pfNativeError,
                    plm_SS_Severity,
                    plm_SS_MsgState,
                    plm_szSqlState);
            }

            printf_s("%ls\n", plm_szErrorMsg);

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
unsigned __stdcall
SQLRoutine(void* parms)
{
    bool        doBackup = (bool)parms;

    wchar_t     sqlCommand[1024];            // way more space than we'll need.
    bool        successDetected = false;

    // ODBC handles
    //
    SQLHENV     henv = nullptr;
    SQLHDBC     hdbc = nullptr;
    SQLHSTMT    hstmt = nullptr;


    swprintf_s(sqlCommand, L"%s DATABASE PUBS %s VIRTUAL_DEVICE='%ls'",
        (doBackup) ? L"BACKUP" : L"RESTORE",
        (doBackup) ? L"TO" : L"FROM",
        wVdsName);

    bool        sentSQL = false;
    int         rc;

    #define            MAX_CONN_OUT 1024
    SQLWCHAR           szOutConn[MAX_CONN_OUT];
    SQLSMALLINT        cbOutConn;

    // Initialize the ODBC environment.
    //
    if (SQLAllocHandle(SQL_HANDLE_ENV, nullptr, &henv) == SQL_ERROR)
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

    // Connect to the server using Trusted connection.
    // Trusted connection uses integrated NT security.
    // If you want to use mixed-mode Authentication, please set Trusted_Connection to no.
    //
    // To use a named instance, change "SERVER=." to "SERVER=.\\instance_name"
    //

    rc = SQLDriverConnectW(
        hdbc,
        nullptr,   // no diaglogs please
        const_cast<SQLWCHAR*>(L"DRIVER={SQL Server};Trusted_Connection=yes;SERVER=."),
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
    printf_s("Executing %ls\n", sqlCommand);

    rc = SQLExecDirectW(hstmt, const_cast<SQLWCHAR*>(sqlCommand), SQL_NTS);

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
            ProcessMessages(SQL_HANDLE_STMT, hstmt, true, nullptr);
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
HANDLE execSQL(bool doBackup)
{
    unsigned int      threadId;
    HANDLE            hThread;

    hThread = (HANDLE)_beginthreadex(
        nullptr, 0, SQLRoutine, (void*)doBackup, 0, &threadId);
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
// VDI data transfer handler.
//
// This routine reads commands from the server until a 'Close' status is received.
// It simply reads or writes a file 'superbak.dmp' in the current directory.
//
void performTransfer(
    IClientVirtualDevice*   vd,
    int                     backup)
{
    FILE*           fh;
    char*           fname = (char*)"superbak.dmp";
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

    fclose(fh);
}
