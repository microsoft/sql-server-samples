using Belgrade.SqlClient;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Threading.Tasks;

namespace FlgpWwiDemo.Controllers
{
    [Route("api/[controller]")]
    public class DemoController : Controller
    {
        IQueryMapper queryMapper = null;

        public DemoController(IQueryMapper queryMapper)
        {
            this.queryMapper = queryMapper;
        }

        // GET api/demo
        [HttpGet]
        [Produces("application/json")]
        public async Task<string> Get()
        {
            decimal result = 0;
            string status = "OK";
            long start = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            long end = 0;
            await this.queryMapper
                .OnError(ex=> status = ex.Message)
                .ExecuteReader("EXEC dbo.report 7", reader => {
                    result = reader.GetDecimal(0);
                    end = DateTimeOffset.Now.ToUnixTimeMilliseconds();
                });
            return "{\"x\":\"" + DateTime.Now.ToUniversalTime().ToString() + "\",\"y\":" + (end-start)  + ",\"start\":" + start + ",\"end\":" + end + ",\"result\":" + result +",\"status\":\"" + status + "\"}";
        }


        // GET api/demo/init
        [HttpGet("init")]
        public async Task Init()
        {
            await this.queryMapper.ExecuteReader("EXEC dbo.[initialize]", _ => { });
        }

        // GET api/demo/regression
        [HttpGet("regression")]
        public async Task Regression()
        {
            await this.queryMapper.ExecuteReader("EXEC dbo.regression", _ => { });
        }

        // GET api/demo/on
        [HttpGet("on")]
        public async Task On()
        {
            await this.queryMapper.ExecuteReader("EXEC dbo.auto_tuning_on", _ => { });
        }


        // GET api/demo/off
        [HttpGet("off")]
        public async Task Off()
        {
            await this.queryMapper.ExecuteReader("EXEC dbo.auto_tuning_off", _ => { });
        }
    }
}
