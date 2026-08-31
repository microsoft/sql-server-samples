## Run this sample
Note: Run this project on a machine joined to a domain that is federated with Microsoft Entra. A contained database user representing your Microsoft Entra ID principal, or one of the groups, you belong to, must exist in the database and must have the CONNECT permission.

1. Before building and running the Integrated project:

+	In Program.cs, locate the following lines of code and replace the server/database name with your server/database name.
```
builder["Data Source"] = "<server name>.database.windows.net "; // replace '<server name>' with your server name
builder["Initial Catalog"] = "demo"; // replace with your database name
```

2. The `builder["Authentication"]` method must be set to `SqlAuthenticationMethod.ActiveDirectoryIntegrated`;

   ![screenshot of visual studio showing builder fields to change](../img/vs-authentication-method-integrated.png)

3. Running this project on a machine joined to a domain that is federated with Microsoft Entra will automatically use your Windows credentials and no password is required. The execution window will indicate a successful connection to the database followed by “Please press any key to stop”:
   ![screenshot of application after successful authentication- "press any key to stop"](../img/integrated-press-any-key-to-stop.png)
