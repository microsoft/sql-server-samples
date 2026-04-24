using Dapper;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Threading.Tasks;

// For more information on enabling Web API for empty projects, visit http://go.microsoft.com/fwlink/?LinkID=397860

namespace ProductCatalog.Controllers
{
    [Route("api/[controller]")]
    public class ProductController : Controller
    {
        IDbConnection connection = null;

        public ProductController(IDbConnection connection)
        {
            this.connection = connection;
        }

        // GET api/Product
        [HttpGet]
        public void Get()
        {
            var QUERY =
@"select ProductID, Name, Color, Price, Quantity, JSON_VALUE(Data, '$.MadeIn') as MadeIn, JSON_QUERY(Tags) as Tags
    from Product
    FOR JSON PATH";

            connection.QueryInto(Response.Body, QUERY);
        }

        // GET api/Product/17
        [HttpGet("{id}")]
        public void Get(int id)
        {
            connection.QueryInto(Response.Body,
                @"select ProductID, Name, Color, Price, Quantity, JSON_VALUE(Data, '$.MadeIn') as MadeIn, JSON_QUERY(Tags) as Tags
                    from Product
                    where ProductID = @id
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER", new { id }, defaultOutput: "{}");
        }

        // POST api/Product
        [HttpPost]
        public async Task Post()
        {
            string product = new StreamReader(Request.Body).ReadToEnd();
            await connection.ExecuteAsync("EXEC dbo.InsertProductFromJson @product", new { product });
        }

        // PATCH api/Product
        [HttpPatch]
        public async Task Patch(int id)
        {
            string product = new StreamReader(Request.Body).ReadToEnd();
            await connection.ExecuteAsync("EXEC dbo.UpsertProductFromJson @id, @product", new { id, product });
        }

        // PUT api/Product/5
        [HttpPut("{id}")]
        public async Task Put(int id)
        {
            string product = new StreamReader(Request.Body).ReadToEnd();
            await connection.ExecuteAsync("EXEC dbo.UpdateProductFromJson @id, @product", new { id, product });
        }

        // DELETE api/Product/5
        [HttpDelete("{id}")]
        public async Task Delete(int id)
        {
            string product = new StreamReader(Request.Body).ReadToEnd();
            await connection.ExecuteAsync("delete Product where ProductId = @id", new { id });
        }

        [HttpGet("Report1")]
        public void Report1()
        {
            var QUERY =
@"select [key] = ISNULL(Color,'N/A'), value = AVG(Quantity)
    from Product
    group by Color
    FOR JSON PATH";

            connection.QueryInto(Response.Body, QUERY);
        }

        // GET api/Product/Report2
        [HttpGet("Report2")]
        public void Report2()
        {
            connection.QueryInto(Response.Body, @"
select  ISNULL(Color,'N/A') as x,
        AVG (Price) / MAX(Price) as y
from Product
group by Color
FOR JSON PATH");
        }

        // GET api/Product/Report2
        [HttpGet("ORM")]
        public List<Product> ORM()
        {
            var products = connection.Query<Product>(@"select * from Product");
            return products.AsList();
        }
    }

    public class Product
    {
        public int ProductID;
        public string Name;
        public string Color;
        public string Size;
        public double Price;
        public int Quantity;
        public object Data;
        public string[] Tags;
    }
}