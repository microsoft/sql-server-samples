using System;
using System.Collections.Generic;

#nullable disable

namespace ContosoHR.Models
{
    public partial class Employee
    {
        public int EmployeeId { get; set; }
        public string Ssn { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public decimal Salary { get; set; }
    }
}
