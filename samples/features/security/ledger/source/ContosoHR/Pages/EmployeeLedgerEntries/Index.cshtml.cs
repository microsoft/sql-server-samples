using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using ContosoHR.Models;

namespace ContosoHR.Pages.EmployeeLedgerEntries
{
    public class IndexModel : PageModel
    {
        private readonly ContosoHR.Models.ContosoHRContext _context;

        public IndexModel(ContosoHR.Models.ContosoHRContext context)
        {
            _context = context;
        }

        public IList<EmployeeLedgerEntry> EmployeeLedgerEntries { get; set; }

        public async Task OnGetAsync()
        {
            EmployeeLedgerEntries = await _context.EmployeeLedgerEntries.FromSqlRaw("EXECUTE dbo.[GetEmployeeLedgerEntries]").ToArrayAsync();
        }
    }
}
