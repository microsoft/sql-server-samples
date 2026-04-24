using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using ContosoHR.Models;

namespace ContosoHR.Pages.Employees
{
    public class IndexModel : PageModel
    {
        private readonly ContosoHR.Models.ContosoHRContext _context;

        public IndexModel(ContosoHR.Models.ContosoHRContext context)
        {
            _context = context;
        }

        public IList<Employee> Employees { get;set; }

        public async Task OnGetAsync()
        {
            //Employees = await _context.Employees.ToListAsync();
            IQueryable<Employee> ledgerEmployeeIQ = from v in _context.Employees
                                                    orderby v.EmployeeId ascending
                                                                  select v;

            Employees = await ledgerEmployeeIQ.AsNoTracking().ToListAsync();
        }
    }
}
