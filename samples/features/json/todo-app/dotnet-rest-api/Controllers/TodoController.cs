using Belgrade.SqlClient;
using Microsoft.AspNetCore.Mvc;
using System.Data.SqlClient;
using System.IO;
using System.Threading.Tasks;

namespace TodoApp.Controllers
{
    [Route("api/[controller]")]
    public class TodoController : Controller
    {
        private readonly IQueryPipe SqlPipe;
        private readonly ICommand SqlCommand;

        public TodoController(ICommand sqlCommand, IQueryPipe sqlPipe)
        {
            this.SqlCommand = sqlCommand;
            this.SqlPipe = sqlPipe;
        }

        // GET api/Todo
        [HttpGet]
        public async Task Get()
        {
            await SqlPipe.Stream("select * from Todo FOR JSON PATH", Response.Body, "[]");
        }

        // GET api/Todo/5
        [HttpGet("{id}")]
        public async Task Get(int id)
        {
            var cmd = new SqlCommand("select * from Todo where Id = @id FOR JSON PATH, WITHOUT_ARRAY_WRAPPER");
            cmd.Parameters.AddWithValue("id", id);
            await SqlPipe.Stream(cmd, Response.Body, "{}");
        }

        // POST api/Todo
        [HttpPost]
        public async Task Post()
        {
            string todo = new StreamReader(Request.Body).ReadToEnd();
            var cmd = new SqlCommand(
        @"insert into Todo
        select *
        from OPENJSON(@todo)
        WITH( title nvarchar(30), description nvarchar(4000), completed bit, dueDate datetime2)");
            cmd.Parameters.AddWithValue("todo", todo);
            await SqlCommand.ExecuteNonQuery(cmd);
        }

        // PATCH api/Todo
        [HttpPatch]
        public async Task Patch(int id)
        {
            string todo = new StreamReader(Request.Body).ReadToEnd();
            var cmd = new SqlCommand(
        @"update Todo
        set title = ISNULL(json.title, title), description = ISNULL(json.description, description),
        completed = ISNULL(json.completed, completed), dueDate = ISNULL(json.dueDate, dueDate)
        from OPENJSON(@todo)
        WITH(   title nvarchar(30), description nvarchar(4000),
                completed bit, dueDate datetime2) AS json
        where Id = @id");
            cmd.Parameters.AddWithValue("id", id);
            cmd.Parameters.AddWithValue("todo", todo);
            await SqlCommand.ExecuteNonQuery(cmd);
        }

        // PUT api/Todo/5
        [HttpPut("{id}")]
        public async Task Put(int id)
        {
            string todo = new StreamReader(Request.Body).ReadToEnd();
            var cmd = new SqlCommand(
        @"update Todo
        set title = json.title, description = json.description,
        completed = json.completed, dueDate = json.dueDate
        from OPENJSON( @todo )
        WITH(   title nvarchar(30), description nvarchar(4000),
                completed bit, dueDate datetime2) AS json
        where Id = @id");
            cmd.Parameters.AddWithValue("id", id);
            cmd.Parameters.AddWithValue("todo", todo);
            await SqlCommand.ExecuteNonQuery(cmd);
        }

        // DELETE api/Todo/5
        [HttpDelete("{id}")]
        public async Task Delete(int id)
        {
            var cmd = new SqlCommand(@"delete Todo where Id = @id");
            cmd.Parameters.AddWithValue("id", id);
            await SqlCommand.ExecuteNonQuery(cmd);
        }
    }
}
