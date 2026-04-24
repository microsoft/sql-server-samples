using Belgrade.SqlClient;
using Microsoft.AspNetCore.Mvc;
using System.Data.SqlClient;
using System.IO;
using System.Threading.Tasks;

namespace ReactCommentsApp.Controllers
{
    [Route("api/[controller]")]
    public class commentsController : Controller
    {
        private readonly IQueryPipe SqlPipe;
        private readonly ICommand SqlCommand;

        public commentsController(ICommand sqlCommand, IQueryPipe sqlPipe)
        {
            this.SqlCommand = sqlCommand;
            this.SqlPipe = sqlPipe;
        }

        // GET api/comment
        [HttpGet]
        public async Task Get()
        {
            await SqlPipe.Stream("select * from Comments FOR JSON PATH", Response.Body, "[]");
        }

        // POST api/comment
        [HttpPost]
        public async Task Post(string author, string text)
        {
            string comment = new StreamReader(Request.Body).ReadToEnd();
            var cmd = new SqlCommand( "insert into Comments values (@author, @text)");
            cmd.Parameters.AddWithValue("author", author);
            cmd.Parameters.AddWithValue("text", text);
            await SqlCommand.ExecuteNonQuery(cmd);
        }
    }
}
