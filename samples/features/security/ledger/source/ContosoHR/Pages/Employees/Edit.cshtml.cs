using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using ContosoHR.Models;
using System.Data;
using Microsoft.Data.SqlClient;

namespace ContosoHR.Pages.Employees
{
    public class EditModel : PageModel
    {
        private readonly ContosoHR.Models.ContosoHRContext _context;

        public EditModel(ContosoHR.Models.ContosoHRContext context)
        {
            _context = context;
        }

        [BindProperty]
        public Employee Employee { get; set; }

        public async Task<IActionResult> OnGetAsync(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            Employee = await _context.Employees.FirstOrDefaultAsync(m => m.EmployeeId == id);

            if (Employee == null)
            {
                return NotFound();
            }
            return Page();
        }

        // To protect from overposting attacks, enable the specific properties you want to bind to.
        // For more details, see https://aka.ms/RazorPagesCRUD.
        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            _context.Attach(Employee).State = EntityState.Modified;

            try
            {
                string userName = HttpContext.User.Identity.Name;
                var ssn = new SqlParameter();
                ssn.ParameterName = @"@SSN";
                ssn.DbType = DbType.AnsiStringFixedLength;
                ssn.Direction = ParameterDirection.Input;
                ssn.Value = Employee.Ssn;
                ssn.Size = ssn.Value.ToString().Length;

                var salary = new SqlParameter();
                salary.ParameterName = @"@Salary";
                salary.DbType = DbType.Currency;
                salary.Direction = ParameterDirection.Input;
                salary.Value = Employee.Salary;

                System.FormattableString query = $"UPDATE [dbo].[Employees] SET [SSN] = {ssn}, [FirstName] = {Employee.FirstName}, [LastName] = {Employee.LastName}, [Salary] = {salary} WHERE [EmployeeID] = {Employee.EmployeeId}";
                string queryString = $"UPDATE [dbo].[Employees] SET [SSN] = '{Employee.Ssn}', [FirstName] = '{Employee.FirstName}', [LastName] = '{Employee.LastName}', [Salary] = '{Employee.Salary}' WHERE [EmployeeID] = '{Employee.EmployeeId}'";
                await _context.Database.ExecuteSqlInterpolatedAsync(query);
                await _context.Database.ExecuteSqlInterpolatedAsync($"INSERT INTO [dbo].[AuditEvents] ([UserName], [Query]) VALUES ({userName}, {queryString})");
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!EmployeeExists(Employee.EmployeeId))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return RedirectToPage("./Index");
        }

        private bool EmployeeExists(int id)
        {
            return _context.Employees.Any(e => e.EmployeeId == id);
        }
    }
}
