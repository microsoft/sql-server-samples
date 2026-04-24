using Belgrade.SqlClient;
using Microsoft.AspNetCore.Mvc;
using System.Data.SqlClient;
using System.IO;
using System.Threading.Tasks;

// For more information on enabling Web API for empty projects, visit http://go.microsoft.com/fwlink/?LinkID=397860

namespace AngularHeroApp.Controllers
{
    [Route("app/[controller]")]
    public class HeroesController : Controller
    {
        private readonly IQueryPipe SqlPipe;
        private readonly ICommand SqlCommand;

        public HeroesController(ICommand sqlCommand, IQueryPipe sqlPipe)
        {
            this.SqlCommand = sqlCommand;
            this.SqlPipe = sqlPipe;
        }

        // GET: app/heroes[?name=<<name>>]
        [HttpGet]
        public async Task Get(string name)
        {
            if(string.IsNullOrEmpty(name))
                await SqlPipe.Stream("select * from Hero for json path", Response.Body, "[]");
            else
            {
                var cmd = new SqlCommand(@"select * from Hero where name like @name for json path");
                cmd.Parameters.AddWithValue("name", "%"+name+"%");
                await SqlPipe.Stream(cmd, Response.Body, "[]");
            }
        }

        // GET app/heroes/5
        [HttpGet("{id}")]
        public async Task Get(int id)
        {
            await SqlPipe.Stream("select * from Hero where id = "+ id +" FOR JSON PATH, WITHOUT_ARRAY_WRAPPER", Response.Body, "{}");
        }

        // POST app/heroes
        [HttpPost]
        public async Task Post()
        {
            string hero = new StreamReader(Request.Body).ReadToEnd();
            var cmd = new SqlCommand(@"EXEC InsertHero @hero");
            cmd.Parameters.AddWithValue("hero", hero);
            await SqlPipe.Stream(cmd,Response.Body,"{}");
        }

        // PUT app/heroes/5
        [HttpPut("{id}")]
        public async Task Put()
        {
            string hero = new StreamReader(Request.Body).ReadToEnd();
            var cmd = new SqlCommand(@"
update Hero set
name = json.name
from openjson(@hero) with (id int, name nvarchar(40)) as json
where Hero.id = json.id");
            cmd.Parameters.AddWithValue("hero", hero);
            await SqlCommand.ExecuteNonQuery(cmd);
        }

        // DELETE app/heroes/5
        [HttpDelete("{id}")]
        public async Task Delete(int id)
        {
            var cmd = new SqlCommand(@"delete Hero where Hero.id = @id");
            cmd.Parameters.AddWithValue("id", id);
            await SqlCommand.ExecuteNonQuery(cmd);
        }
    }
}