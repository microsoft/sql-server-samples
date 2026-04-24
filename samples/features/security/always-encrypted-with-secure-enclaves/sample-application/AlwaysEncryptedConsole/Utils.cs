//********************************************************* 
// Copyright (c) Microsoft. All rights reserved. 
// This code is licensed under the MIT License (MIT). 
// THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF 
// ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY 
// IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR 
// PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT. 
// 
// Author: Michael Howard, Azure Data Security
//*********************************************************

using System.Text;
using Azure.Core;
using Azure.Identity;
using Microsoft.Data.SqlClient;
using Microsoft.Data.SqlClient.AlwaysEncrypted.AzureKeyVaultProvider;

partial class Program
{
    // Helper function to dump binary data
    // Can truncate the output if needed
    public static string ByteArrayToHexString(byte[] byteArray, int maxLen = 16)
    {
        StringBuilder hex = new(byteArray.Length * 2);
        foreach (byte b in byteArray)
            hex.AppendFormat("{0:x2}", b);

        return hex.ToString()[..maxLen];
    }

    // Build SQL Connection String 
    public static string GetSQLConnectionString(bool useAE = true)
    {
        const string _EnvVar = "ConnectContosoHR";

        string? sqlConn = 
            Environment.GetEnvironmentVariable(_EnvVar, EnvironmentVariableTarget.Process) 
            ?? throw new ArgumentException($"Missing environment variable, {_EnvVar}");

        // Add AE settings if needed
        // You could also use a connection string builder, SqlConnectionStringBuilder 
        if (useAE)
            sqlConn += ";Column Encryption Setting=Enabled;Attestation Protocol=None;";

        return sqlConn;
    }

    // Login to Azure and get token to Azure SQL DB OAuth2 token
    // This uses Azure CLI for authentication, but you could change this 
    // to use other methods such as Managed Identity, Service Principal, etc.
    // You'll get an error if you don't have the Azure CLI installed and have yet to login.
    // Learn more about the various Azure token credential sources at
    // https://learn.microsoft.com/en-us/dotnet/api/azure.identity.defaultazurecredential?view=azure-dotnet
    public static (TokenCredential? tok, string? oauth2Sql) LoginToAure()
    {
        try
        {
            var credential = new AzureCliCredential();
            var oauth2TokenSql = credential.GetToken(
                    new TokenRequestContext(
                        ["https://database.windows.net/.default"])).Token;
            return (credential, oauth2TokenSql);
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex.Message);
            return (null, null);
        }
    }

    // We need to register the use of AKV for AE, do these once per app on startup
    public static void RegisterAkvForAe(TokenCredential cred)
    {
        var akvAeProvider = new SqlColumnEncryptionAzureKeyVaultProvider(cred);
        SqlConnection.RegisterColumnEncryptionKeyStoreProviders(
            customProviders: new Dictionary<string, SqlColumnEncryptionKeyStoreProvider>() {
                { SqlColumnEncryptionAzureKeyVaultProvider.ProviderName, akvAeProvider }
            });
    }
}
