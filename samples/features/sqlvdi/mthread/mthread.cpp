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
// mthread.cpp  : 
//  
// Test & demonstrate the use of multiple streams from a single process.
//
// This is a sample program used to demonstrate the Virtual Device Interface
// feature of Microsoft SQL Server.
//
// The program will backup or restore the 'pubs' sample database.
//
// The program requires two command line parameters.  
// 1)
// One of:
//  b   perform a backup
//  r   perform a restore
//
// 2)
// The number of streams to use, 1-32.
//  

#define _WIN32_DCOM

#include <objbase.h>    // for 'CoInitialize()'
#include <stdio.h>      // for file operations
#include <ctype.h>      // for toupper ()
#include <process.h>    // for C library-safe _beginthreadex,_endthreadex
#include <windows.h>

#include "vdi.h"        // interface declaration
#include "vdierror.h"   // error constants
#include "vdiguid.h"    // define the GUIDs 

void LogError(
    const char*         location,    // must always be provided
    const char*         description, // NULL is acceptable
    DWORD               errCode);    // windows status code

int performTransfer(
    IClientVirtualDevice*   vd,
    int                     backup,
    int                     streamId);

HANDLE execSQL(bool doBackup, int nStreams);

int startSecondaries(
    IClientVirtualDeviceSet2*    vds,
    HANDLE                       hSQLProcess,    // handle to process dealing with the SQL
    int                          nStreams);      // number of i/o streams

unsigned __stdcall
runSecondary(void* parms);

// Using a GUID for the VDS Name is a good way to assure uniqueness.
//
WCHAR    wVdsName[50];

//
// main function
//
int main(int argc, char* argv[])
{
    HRESULT                     hr;
    IClientVirtualDeviceSet2*   vds = nullptr;
    VDConfig                    config;
    bool                        badParm = true;
    bool                        doBackup;
    HANDLE                      hProcess;
    int                         termCode = -1;
    int                         nStreams = 1;

    // Check the input parm
    //
    if (argc == 3)
    {
        sscanf_s(argv[2], "%d", &nStreams);

        switch (toupper(argv[1][0]))
        {
        case 'B':
            doBackup = true;
            badParm = false;
            break;

        case 'R':
            doBackup = false;
            badParm = false;
            break;
        }
    }

    if (badParm)
    {
        printf("usage: mthread {B|R} <nStreams>\n"
            "Demonstrate a multistream Backup or Restore using the Virtual Device Interface\n");
        exit(1);
    }

    // 1..32 streams.
    //
    if (nStreams < 1)
        nStreams = 1;
    else if (nStreams > 32)
        nStreams = 32;

    printf("Performing a %s using %d virtual device(s).\n",
        (doBackup) ? "BACKUP" : "RESTORE", nStreams);

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
        // This failure might happen if the DLL was not registered.
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
    config.deviceCount = nStreams;

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

    // Send the SQL command, via isql in a subprocess.
    //
    printf("\nSending the SQL...\n");

    hProcess = execSQL(doBackup, nStreams);
    if (hProcess == nullptr)
    {
        printf("execSQL failed.\n");
        goto shutdown;
    }


    // Wait for the server to connect, completing the configuration.
    // Notice that we wait a maximum of 15 seconds.
    //
    printf("\nWaiting for SQL to complete configuration...\n");

    hr = vds->GetConfiguration(15000, &config);
    if (FAILED(hr))
    {
        printf("VDS::Getconfig fails: x%X\n", hr);
        goto shutdown;
    }

    // Handle the virtual devices in secondary processes.
    //
    printf("\nSpawning secondary threads..\n");
    termCode = startSecondaries(vds, hProcess, nStreams);

shutdown:

    // Close the set
    //
    vds->Close();

    // COM reference counting: Release the interface.
    //
    vds->Release();

exit:

    // Uninitialize COM Library
    //
    CoUninitialize();

    return termCode;
}

//
// Execute a basic backup/restore, by starting 'isql' in a subprocess.
//
// Returns:
//  NULL    : failed to start isql
//  else    : process handle
//
HANDLE execSQL(bool doBackup, int nStreams)
{
    WCHAR                   cmd[5000];
    WCHAR                   extend[100];
    PROCESS_INFORMATION     pi;
    STARTUPINFO             si;
    int                     ix;

    // To use a named instance, change "-S ." to "-S .\\instance_name"
    swprintf_s(cmd, L"osql -S . -E -b -Q\"%s DATABASE PUBS %s VIRTUAL_DEVICE='%ls'",
        (doBackup) ? L"BACKUP" : L"RESTORE",
        (doBackup) ? L"TO" : L"FROM",
        wVdsName);

    for (ix = 1; ix < nStreams; ix++)
    {
        swprintf_s(extend, L", VIRTUAL_DEVICE='%ls%d'", wVdsName, ix);
        wcscat_s(cmd, extend);
    }

    wcscat_s(cmd, L"\"");

    wprintf(L"Submitting SQL:\n%s\n\n", cmd);

    // use my process for startup info
    //
    GetStartupInfo(&si);

    if (!CreateProcess(nullptr, cmd, nullptr, nullptr,
        true,   // inherit handles (stdin/stdout)
        0,      // creation flags,
        nullptr, nullptr,
        &si,    // startup info
        &pi))   // out: process info
    {
        LogError("startSecondary", "CreateProcess", GetLastError());
        return nullptr;
    }

    CloseHandle(pi.hThread);

    // Return the process handle
    //
    return (pi.hProcess);
}

//-----------------------------------------------------------
//
// A parmameter block to use when spawning secondaries.
//
struct THREAD_PARMS {
    IClientVirtualDeviceSet* vds;
    int                      streamId;
};


//-----------------------------------------------------------
// Invoke the secondary threads, and wait for all children
// to complete.
//
// Returns: 0 if no errors were detected.
//
//
int
startSecondaries(
    IClientVirtualDeviceSet2*    vds,
    HANDLE                       hSQLProcess,    // handle to process dealing with the SQL
    int                          nStreams        // number of i/o streams
)
{
    THREAD_PARMS    parms[32];      // each thread needs its own parm block
    int             ix, nActive;
    HANDLE          children[33];    // 32 is maximum number of streams.

    // plus one for the isql process.
    DWORD           waitStatus, exitCode;
    unsigned        threadId;

    for (ix = 0; ix < nStreams; ix++)
    {
        // All threads share the same virtual device set,
        // but must operate on different virtual devices.
        //
        parms[ix].vds = vds;
        parms[ix].streamId = ix;

        children[ix] = (HANDLE)_beginthreadex(
            nullptr, 0, runSecondary, (void*)&parms[ix], 0, &threadId);

        if (children[ix] == nullptr)
        {
            printf("Failed to create thread. errno is %d\n", errno);
            goto errorExit;
        }

        printf("\nStarted thread %d\n", threadId);
    }

    // Add the isql process into the array
    //
    children[nStreams] = hSQLProcess;
    nActive = nStreams + 1;

    // Wait for all to finish.
    // Max wait is one minute for this tiny test.
    //
    printf("All children are now running.\n"
        "Waiting for their completion...\n");

    waitStatus = WaitForMultipleObjects(nActive, children,
        true, 60000);

    if (waitStatus < WAIT_OBJECT_0 ||
        waitStatus >= WAIT_OBJECT_0 + nActive)
    {
        LogError("startSecondary", "WaitForMultiple", GetLastError());
        printf("Unexpected wait code: %d\n", waitStatus);
        goto errorExit;
    }

    // All of the children have completed.
    // Get the completion code from 'isql' to check for sucess.
    //
    if (!GetExitCodeProcess(hSQLProcess, &exitCode))
    {
        LogError("startSecondary", "GetExitCode", GetLastError());
        goto errorExit;
    }

    if (exitCode != 0)
    {
        printf("The SQL operation failed with code %d\n", exitCode);
        goto errorExit;
    }

    printf("The SQL operation was sucessful.\n");

    // Be sure to close handles when finished with them.
    //
    // Notice that in our trivial error handling here we
    // don't bother closing them, since handles are
    // automatically closed as part of process termination.
    //
    for (ix = 0; ix < nActive; ix++)
    {
        CloseHandle(children[ix]);
    }

    return 0;

errorExit:
    // Handle all problems in a trivial fashion:
    //  SignalAbort() will cause all processes using the virtual device set
    //  to terminate processing.
    //
    vds->SignalAbort();

    //  However, since the threads are using the virtual device set allocated
    //  by the main thread, we can't let the main thread close the set before
    //  the threads are finished with it. There are two options:
    //  1) exit the process immediately.
    //  2) wait for the threads to terminate.
    //
    //  Option 2 is "cleaner" but requires more code, so we just exit here:
    //
    ExitProcess((unsigned)-1);

    return -1;  // ExitProcess doesn't return; this avoids a compiler error.
}

//------------------------------------------------------------------
// Perform secondary client processing from within a thread.
// Exits with 0 if no errors detected, else nonzero.
// The caller must setup a THREAD_PARMS parameter block when
// spawning the thread.
//
unsigned __stdcall
runSecondary(void* parms)
{
    HRESULT                         hr;
    WCHAR                           devName[100];
    IClientVirtualDevice*           vd;
    VDConfig                        config;
    int                             termCode;

    // Fetch the input parms
    //
    int                         streamId = ((THREAD_PARMS*)parms)->streamId;
    IClientVirtualDeviceSet*    vds = ((THREAD_PARMS*)parms)->vds;

    // Build the name of the device assigned to this thread.
    //
    if (streamId == 0)
    {
        // The first device has the same name as the set.
        //
        wcscpy_s(devName, wVdsName);
    }
    else
    {
        // For this example, we've simply appended a number
        // for additional devices.  You are free to name them
        // as you wish.
        //
        swprintf_s(devName, L"%s%d", wVdsName, streamId);
    }

    // Open the device assigned to this thread.
    //
    hr = vds->OpenDevice(devName, &vd);
    if (FAILED(hr))
    {
        wprintf(L"OpenDevice fails on %ls: x%X", devName, hr);
        termCode = -1;
        goto errExit;
    }

    // Grab the config to figure out data direction
    //
    hr = vds->GetConfiguration(INFINITE, &config);
    if (FAILED(hr))
    {
        wprintf(L"VDS::Getconfig fails: x%X\n", hr);
        termCode = -1;
        goto errExit;
    }

    printf("\nPerforming data transfer...\n");

    termCode = performTransfer(vd,
        (config.features & VDF_WriteMedia), streamId);

errExit:

    // If errors were detected, force an abort.
    //
    if (termCode != 0)
    {
        vds->SignalAbort();
    }

    return ((unsigned)termCode);

}



// This routine reads commands from the server until a 'Close' status is received.
// It simply synchronously reads or writes a file on the root of the current drive.
//
// Returns 0, if no errors are detected, else non-zero.
//
int performTransfer(
    IClientVirtualDevice*   vd,
    int                     backup,
    int                     streamId)
{
    FILE*           fh;
    char            fname[80];
    VDC_Command*    cmd;
    DWORD           completionCode;
    DWORD           bytesTransferred;
    HRESULT         hr;
    int             termCode = -1;

    sprintf_s(fname, "multi.%d.dmp", streamId);

    errno_t error = fopen_s(&fh, fname, (backup) ? "wb" : "rb");
    if (error != 0)
    {
        printf("Failed to open: %s\n", fname);
        return -1;
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
        termCode = 0;
    }

    fclose(fh);

    return termCode;
}


//--------------------------------------------------------------------
// 
// A simple error logger.
//
void LogError(
    const char*     location,    // must always be provided
    const char*     description, // NULL is acceptable
    DWORD           errCode)     // windows status code
{
    LPWSTR lpMsgBuf = nullptr;

    printf(
        "Error at %s: %s StatusCode: %X\n",
        location,
        (description == nullptr) ? "" : description,
        errCode);

    // Attempt to explain the code
    //
    if (errCode != 0 && FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER |
        FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        nullptr,
        errCode,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
        reinterpret_cast<LPWSTR>(&lpMsgBuf), 0, nullptr)) // Process any inserts in lpMsgBuf.
    {
        printf("Explanation: %ls\n", lpMsgBuf);
        LocalFree(lpMsgBuf);
    }
}

