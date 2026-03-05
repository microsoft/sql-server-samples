using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;

#nullable disable

namespace ContosoHR.Models
{
    public partial class ContosoHRContext : DbContext
    {
        public ContosoHRContext(DbContextOptions<ContosoHRContext> options)
            : base(options)
        {
        }

        public virtual DbSet<Employee> Employees { get; set; }
    }
}
