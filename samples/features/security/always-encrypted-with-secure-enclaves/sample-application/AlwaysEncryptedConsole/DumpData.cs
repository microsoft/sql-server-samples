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

using Microsoft.Data.SqlClient;

partial class Program
{
    // Displays rows and  cols from a SqlDataReader query result
    public static void DumpData(SqlDataReader? data)
    {
        if (data is null)
        {
            Console.WriteLine("No data");
            return;
        }

        // get column headers
        Console.WriteLine("Fetching Data");
        for (int i = 0; i < data.FieldCount; i++)
            Console.Write(data.GetName(i) + ", ");

        Console.WriteLine();

        // get data
        while (data.Read())
        {
            for (int i = 0; i < data.FieldCount; i++)
            {
                var value = data.GetValue(i);

                if (value is not null)
                {
                    var type = data.GetFieldType(i);

                    // if the data is a byte array (ie; ciphertext)
                    // dump the first 16 bytes of hex string
                    if (type == typeof(byte[]))
// Possible null reference argument. There *IS* a check two lines up!
#pragma warning disable CS8604 
                        value = ByteArrayToHexString(value as byte[], 16);
#pragma warning restore CS8604 
                }
                else
                {
                    value = "?";
                }

                Console.Write(value + ", ");
            }
            Console.WriteLine();
        }
    }
}

