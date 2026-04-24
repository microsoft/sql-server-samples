using EFGetStarted.AspNetCore.NewDb.Models;
using Microsoft.AspNetCore.Mvc;
using System.Linq;

namespace EFGetStarted.AspNetCore.NewDb.Controllers
{
    public class BlogsController : Controller
    {
        private BloggingContext _context;

        public BlogsController(BloggingContext context)
        {
            _context = context;
        }

        public IActionResult Index()
        {
            return View(_context.Blogs.ToList());
        }

        public IActionResult Search(string Owner)
        {
            // Option 1: .Net side filter using LINQ:
            var blogs = _context.Blogs
                            .Where(b => b.Owner.Name == Owner)
                            .ToList();

            // Option 2: SQL Server filter using T-SQL:
            //var blogs = _context.Blogs
            //                .FromSql<Blog>(@"SELECT * FROM Blogs
            //                    WHERE JSON_VALUE(Owner, '$.Name') = {0}", Owner)
            //                .ToList();

            return View("Index", blogs);
        }

        public IActionResult Create()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Create(Blog blog)
        {
            if (ModelState.IsValid)
            {
                _context.Blogs.Add(blog);
                _context.SaveChanges();
                return RedirectToAction("Index");
            }

            return View(blog);
        }
    }
}