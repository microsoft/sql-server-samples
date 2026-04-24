using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.AspNetCore.Identity;

#nullable disable

namespace ContosoHR.Models
{
    public partial class ContosoHRContext : IdentityDbContext
    {
        public ContosoHRContext(DbContextOptions<ContosoHRContext> options)
            : base(options)
        {
        }

        public virtual DbSet<Employee> Employees { get; set; }

        public virtual DbSet<EmployeeLedgerEntry> EmployeeLedgerEntries { get; set; }

        public virtual DbSet<AuditEvent> AuditEvents { get; set; }

        public virtual DbSet<LedgerVerification> LedgerVerifications { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.Entity<EmployeeLedgerEntry>(
                entry =>
                {
                    entry.HasNoKey();
                }
            );
            modelBuilder.Entity<AuditEvent>(
                entry =>
                {
                    entry.HasNoKey();
                }
            );
            modelBuilder.Entity<LedgerVerification>(
                entry =>
                {
                    entry.HasNoKey();
                }
);
        }
    }
}
