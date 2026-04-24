using Microsoft.SqlServer.Server;
using System;
using System.Data.SqlTypes;
using System.Net;
using System.Threading;

/// <summary>
/// Provides CURL-like functionalities in T-SQL code.
/// </summary>
public partial class Curl
{
    static Curl()
    {
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
    }

    [SqlFunction]
    [return: SqlFacet(MaxSize = -1)]
    public static SqlChars Get(SqlChars H, SqlChars url)
    {

        var client = new WebClient();
        AddHeader(H, client);
        return new SqlChars(
                client.DownloadString(
                    Uri.EscapeUriString(url.ToSqlString().Value)
                    ).ToCharArray());
    }

    [SqlProcedure]
    public static void Post(SqlChars H, SqlChars d, SqlChars url)
    {

        var client = new WebClient();
        AddHeader(H, client);
        if (d.IsNull)
            throw new ArgumentException("You must specify data that will be sent to the endpoint", "@d");
        var response =
                client.UploadString(
                    Uri.EscapeUriString(url.ToSqlString().Value),
                    d.ToSqlString().Value
                    );
        SqlContext.Pipe.Send("Request is executed. " + response);
    }

    [SqlProcedure]
    public static void PostWithRetry(SqlChars H, SqlChars d, SqlChars url)
    {

        var client = new WebClient();
        AddHeader(H, client);
        if (d.IsNull)
            throw new ArgumentException("You must specify data that will be sent to the endpoint", "@d");
        int i = RETRY_COUNT;
        string response = "";
        do try
            {
                response =
                        client.UploadString(
                            Uri.EscapeUriString(url.ToSqlString().Value),
                            d.ToSqlString().Value
                            );
                i = -1;
                break;
            }
            catch (Exception ex)
            {
                SqlContext.Pipe.Send("Error:\t" + ex.Message + ". Waiting " + DELAY_ON_ERROR + "ms.");
                i--;
                Thread.Sleep(DELAY_ON_ERROR);
            }
        while (i > 0);
        if(i==-1)
            SqlContext.Pipe.Send("Request is executed." + response);
    }

    static readonly int RETRY_COUNT = 3;
    static readonly int DELAY_ON_ERROR = 50;

    private static void AddHeader(SqlChars H, WebClient client)
    {
        if (!H.IsNull)
        {
            var header = H.ToSqlString().Value;
            if (!string.IsNullOrWhiteSpace(header))
                foreach(string h in header.Split(';'))
                    client.Headers.Add(h);
        }
    }
};