using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using ProductCatalog.Models;
using System;
using System.Collections.Generic;
using System.Linq;

namespace ProductCatalog.Controllers
{
    public class ProductCatalogController : Controller
    {
        private ProductCatalogContext _context;
        private readonly ILogger<ProductCatalogController> _logger;

        public ProductCatalogController (ProductCatalogContext context, ILogger<ProductCatalogController> logger)
        {
            _logger = logger;
            _context = context;
        }

        [HttpGet]
        public IActionResult Index()
        {
            ViewData["page"] = "index";
            return View(_context.Products.AsEnumerable());
        }

        // POST api/ProductCatalog/Add
        public IActionResult Add(Product p)
        {
            try
            {
                _context.Products.Add(p);
                _context.SaveChanges();
                return Redirect("/ProductCatalog/Index");
            } catch (Exception)
            {
                return Redirect("/ProductCatalog/Index");
            }
        }

        public IActionResult Report1()
        {
            ViewData["page"] = "report1";
            return View();
        }

        public IActionResult Report2()
        {
            ViewData["page"] = "report2";
            return View();
        }

        [HttpGet(Name = "GetAll")]
        public IEnumerable<Product> GetAll()
        {
            return _context.Products.AsEnumerable<Product>();
        }

        [HttpGet("GetById")]
        public IActionResult GetById(int id)
        {
            var product = _context.Products.FirstOrDefault(p=>p.ProductId == id);
            if (product == null)
            {
                return NotFound();
            }
            return new ObjectResult(product);
        }
    }
}