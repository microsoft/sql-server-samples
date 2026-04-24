using SensorModule;
using SensorModule.Models;
using Microsoft.EntityFrameworkCore;

namespace SensorModule.DataStore
{

  public class DatabaseContext : DbContext
  {
    private string _sqlConnectionString = string.Empty;

    public DatabaseContext(string sqlConnectionString)
    {
      this._sqlConnectionString = sqlConnectionString;
    }
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
      optionsBuilder.UseSqlServer(_sqlConnectionString);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
      modelBuilder.Entity<OnnxModel>().ToTable("models");
    }

    public DbSet<RealtimeWindTurbineRecord> RealtimeWindTurbineRecord { get; set; }
    public DbSet<RealtimeSensorRecord> RealtimeSensorRecord { get; set; }
  }
}
