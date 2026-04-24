using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.SqlServer;

namespace AzureSqlEFSample
{
    public class EFSampleContext : DbContext
    {
        string _connectionString;
        public EFSampleContext(string connectionString)
        {
            this._connectionString = connectionString;

        }
        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            optionsBuilder.UseSqlServer(this._connectionString);
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Task> Tasks { get; set; }
    }
}