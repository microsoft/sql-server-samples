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
// vdipipesample.cpp
//
// This is a sample program used to demonstrate the Virtual Device Interface
// feature of Microsoft SQL Server. This code implements the client side of
// the Virtual Device Interface and uses sqlcmd to issue a T-SQL statement
// to start the server side of the backup or restore.
//
// The program will backup or restore a database.
//
// The program accepts 6 command line parameters.
//
// One of:
//  b   perform a backup
//  r   perform a restore
// One of:
//  d   perform a backup/restore on a database
//  l   perform a backup/restore on a log
// The DB Name
//  databaseName
// The SQL username
//  sa
// The SQL Password
//  MyPassword1!
// And the filename:
//  filename.bak
//

#include <cstdio>  // for file operations
#include <ctype.h> // for toupper ()
#include <cstdio>
#include <iostream>
#include <memory>
#include <cstring> // for memset
#include <stdexcept>
#include <string>
#include <unistd.h>
#include <uuid/uuid.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "vdi.h"      // interface declaration
#include "vdierror.h" // error constants

using namespace std;

void performTransfer(
    ClientVirtualDevice* vd,
    int                  backup,
    char*                fname);

shared_ptr<FILE> sendSQL(bool  doBackup,
                         bool  dataBackup,
                         char* databaseName,
                         char* userName,
                         char* password);

// Using a GUID for the VDS Name is a good way to assure uniqueness.
//
static char wVdsName [50];

//
// main function
//
int main(int argc, char* argv[])
{
    ClientVirtualDeviceSet* vds = NULL;
    ClientVirtualDevice* vd = NULL;
    int status;

    VDConfig config;
    bool badParm = false;
    bool doBackup = true;
    bool dataBackup = true;
    char* databaseName = nullptr;
    char* userName = nullptr;
    char* password = nullptr;
    char* backupFile = nullptr;
    shared_ptr<FILE>            processPipe;

    // Check the input parm
    //
    if (argc == 7)
    {
        if (toupper(argv[1][0]) == 'B')
        {
            doBackup = true;
        }
        else if (toupper(argv[1][0]) == 'R')
        {
            doBackup = false;
        }
        else
        {
            badParm = true;
        }

        if (toupper(argv[2][0]) == 'D')
        {
            dataBackup = true;
        }
        else if (toupper(argv[2][0]) == 'L')
        {
            dataBackup = false;
        }
        else
        {
            badParm = true;
        }

        databaseName = &argv[3][0];
        userName = &argv[4][0];
        password = &argv[5][0];
        backupFile = &argv[6][0];
    }
    else
    {
        badParm = true;
    }

    if (badParm)
    {
        printf("usage: vdipipesample {B|R} {D|L} <databaseName> <userName> <password> <filename>\n"
               "Demonstrate a Backup or Restore using the Virtual Device Interface\n");
        return 1;
    }

    umask(0);
    vds = new ClientVirtualDeviceSet();

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
    uuid_t vdsId;
    uuid_generate(vdsId);
    uuid_unparse(vdsId, wVdsName);

    // Create the virtual device set
    //
    status = vds->Create(wVdsName, &config);
    if (status != 0)
    {
        printf("VDS::Create fails: x%X", status);
        goto exit;
    }

    // Send the SQL command, by starting 'sqlcmd' in a new process.
    //
    printf("\nSending the SQL...\n");

    processPipe = sendSQL(doBackup, dataBackup, databaseName, userName, password);
    if (!processPipe)
    {
        printf("sendSQL failed.\n");
        goto shutdown;
    }

    printf("\nGetting configuration.\n");
    // Wait for the server to connect, completing the configuration.
    //
    status = vds->GetConfiguration(10000, &config);
    if (status != 0)
    {
        printf("VDS::Getconfig fails: x%X\n", status);
        if (status == VD_E_TIMEOUT)
        {
            printf("Timed out. Was Microsoft SQLServer running?\n");
        }
        goto shutdown;
    }

    printf("Features returned by SQL Server: 0x%x\n", config.features);

    printf("\nOpening the device.\n");
    // Open the single device in the set.
    //
    status = vds->OpenDevice(wVdsName, &vd);
    if (status != 0)
    {
        printf("VDS::OpenDevice fails: x%X\n", status);
        goto shutdown;
    }

    printf("\nPerforming data transfer...\n");

    performTransfer(vd, doBackup, backupFile);

shutdown:

    // Close the set
    //
    vds->Close();

exit:

    // Print out any messages from SQLCMD
    //
    if (processPipe)
    {
        char line[1024];
        while (fgets(line, 1024, processPipe.get()))
        {
            printf("%s", line);
        }
    }

    return 0;
}

// Execute a basic backup/restore, by spawning a process to execute 'sqlcmd'.
//
shared_ptr<FILE> sendSQL(bool  doBackup,
                         bool  dataBackup,
                         char* databaseName,
                         char* userName,
                         char* password)
{
    printf("Connecting to SQL Server.");
    char sqlCommand [1024]; // plenty of space for our purpose

    sprintf(sqlCommand,
            "sqlcmd -U %s -P %s -S . -Q \"%s %s %s %s VIRTUAL_DEVICE='%s' WITH %s, MAXTRANSFERSIZE=1048576 \"",
            userName,
            password,
            (doBackup) ? "BACKUP" : "RESTORE",
            (dataBackup) ? "DATABASE" : "LOG",
            databaseName,
            (doBackup) ? "TO" : "FROM",
            wVdsName,
            (doBackup) ? "FORMAT" : "REPLACE");

    shared_ptr<FILE> pipe(popen(sqlCommand, "r"), pclose);

    return pipe;
}

// This routine reads commands from the server until a 'Close' status is received.
//
void performTransfer(
    ClientVirtualDevice* vd,
    int                  backup,
    char*                fname)
{
    FILE*          fh;
    VDC_Command*   cmd;
    int completionCode;
    size_t bytesTransferred;
    int status;

    fh = fopen(fname, (backup) ? "wb" : "rb");
    if (fh == NULL)
    {
        printf("Failed to open: %s\n", fname);
        return;
    }

    // Timeout in seconds
    //
    int timeout = 90;
    while ((status = vd->GetCommand(timeout, &cmd)) == 0)
    {
        bytesTransferred = 0;
        switch (cmd->commandCode)
        {
        case VDC_Read:
            bytesTransferred = fread(cmd->buffer, 1, cmd->size, fh);
            if (bytesTransferred == (size_t)cmd->size)
            {
                completionCode = ERROR_SUCCESS;
            }
            else
            {
                // assume failure is eof
                completionCode = ERROR_HANDLE_EOF;
            }
            break;

        case VDC_Write:
            bytesTransferred = fwrite(cmd->buffer, 1, cmd->size, fh);
            if (bytesTransferred == (size_t)cmd->size)
            {
                completionCode = ERROR_SUCCESS;
            }
            else
            {
                // assume failure is disk full
                completionCode = ERROR_DISK_FULL;
            }
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

        status = vd->CompleteCommand(cmd, completionCode, bytesTransferred, 0);
        printf("Completed command code: %i, completionCode: %i, bytes; %li \n",
               cmd->commandCode, completionCode, bytesTransferred);
        if (status != 0)
        {
            printf("Completion Failed: x%X\n", status);
            break;
        }
    }

    if (status != VD_E_CLOSE)
    {
        printf("Unexpected termination: x%X\n", status);
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

