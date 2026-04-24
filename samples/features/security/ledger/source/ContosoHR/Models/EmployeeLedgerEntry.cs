using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ContosoHR.Models
{
    public class EmployeeLedgerEntry
    {
        public DateTime CommitTime { get; set; }
        public string UserName { get; set; }
        public string Operation { get; set; }
        public int EmployeeId { get; set; }
        public string Ssn { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public decimal Salary { get; set; }
    }
}