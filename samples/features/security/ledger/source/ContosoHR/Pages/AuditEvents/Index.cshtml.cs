using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using ContosoHR.Models;

namespace ContosoHR.Pages.AuditEvents
{
    public class IndexModel : PageModel
    {
        private readonly ContosoHR.Models.ContosoHRContext _context;

        public IndexModel(ContosoHR.Models.ContosoHRContext context)
        {
            _context = context;
        }

        public IList<AuditEvent> AuditEvents { get; set; }

        public async Task OnGetAsync()
        {
            AuditEvents = await _context.AuditEvents.FromSqlRaw("EXECUTE [dbo].[GetAuditEvents]").ToArrayAsync();
            /*
            IQueryable<AuditEvent> auditEventIQ = from e in _context.AuditEvents
                                                                  orderby e.TimeStamp descending
                                                                  select e;
            AuditEvents = await auditEventIQ.AsNoTracking().ToListAsync();
            */
        }
    }
}
