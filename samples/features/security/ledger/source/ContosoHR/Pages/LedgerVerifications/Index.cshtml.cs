using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using ContosoHR.Models;

namespace ContosoHR.Pages.LedgerVerifications
{
    public class IndexModel : PageModel
    {
        private readonly ContosoHR.Models.ContosoHRContext _context;

        public IndexModel(ContosoHR.Models.ContosoHRContext context)
        {
            _context = context;
        }

        public IList<LedgerVerification> LedgerVerifications { get; set; }

        public async Task OnGetAsync(string sortOrder)
        {
            LedgerVerifications = await _context.LedgerVerifications.FromSqlRaw("EXECUTE [dbo].[GetLedgerVerifications]").ToArrayAsync();
            /*
            IQueryable<LedgerVerification> ledgerVerificationIQ = from v in _context.LedgerVerifications
                                                                  orderby v.TimeStamp descending
                                                                  select v;

            LedgerVerifications = await ledgerVerificationIQ.AsNoTracking().ToListAsync();
            */
        }

        public async Task<IActionResult> OnPostVerifyAsync()
        {
            System.FormattableString query = $"EXECUTE [dbo].[VerifyLedger]";
            await _context.Database.ExecuteSqlInterpolatedAsync(query);
            return RedirectToPage("/LedgerVerifications/Index");
        }
    }
}
