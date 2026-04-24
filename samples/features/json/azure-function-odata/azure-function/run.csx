using Belgrade.SqlClient.SqlDb;
using System.Net;
using System.Configuration;
using SqlServerRestApi;

public static async Task<HttpResponseMessage> Run(HttpRequestMessage req, TraceWriter log)
{
    log.Info("Started execution...");

    try{
        string ConnectionString = ConfigurationManager.ConnectionStrings["azure-db-connection"].ConnectionString;
        var sqlQuery = new QueryPipe(ConnectionString);
        var tableSpec = new SqlServerRestApi.TableSpec("sys","objects", "object_id,name,type,schema_id,create_date");
        return await req.CreateODataResponse(tableSpec, sqlQuery);

    } catch (Exception ex) {
        log.Error($"C# Http trigger function exception: {ex.Message}");
        return new HttpResponseMessage() { Content = new StringContent(ex.Message), StatusCode = HttpStatusCode.InternalServerError };
    }
}