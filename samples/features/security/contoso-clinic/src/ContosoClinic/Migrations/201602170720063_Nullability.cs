namespace ContosoClinic.Migrations
{
    using System;
    using System.Data.Entity.Migrations;

    public partial class Nullability : DbMigration
    {
        public override void Up()
        {
            AlterColumn("dbo.Patients", "SSN", c => c.String(nullable: false, maxLength: 11, fixedLength: true, unicode: false));
            AlterColumn("dbo.Patients", "LastName", c => c.String(nullable: false, maxLength: 50));
            AlterColumn("dbo.Patients", "StreetAddress", c => c.String(nullable: false, maxLength: 50));
            AlterColumn("dbo.Patients", "City", c => c.String(nullable: false, maxLength: 50));
            AlterColumn("dbo.Patients", "ZipCode", c => c.String(nullable: false, maxLength: 5, fixedLength: true, unicode: false));
            AlterColumn("dbo.Patients", "State", c => c.String(nullable: false, maxLength: 2, fixedLength: true, unicode: false));
            AlterColumn("dbo.Visits", "Reason", c => c.String(nullable: false, maxLength: 4000));
            AlterColumn("dbo.Visits", "Treatment", c => c.String(nullable: false, maxLength: 4000));
        }

        public override void Down()
        {
            AlterColumn("dbo.Visits", "Treatment", c => c.String(maxLength: 4000));
            AlterColumn("dbo.Visits", "Reason", c => c.String(maxLength: 4000));
            AlterColumn("dbo.Patients", "State", c => c.String(maxLength: 2, fixedLength: true, unicode: false));
            AlterColumn("dbo.Patients", "ZipCode", c => c.String(maxLength: 5, fixedLength: true, unicode: false));
            AlterColumn("dbo.Patients", "City", c => c.String(maxLength: 50));
            AlterColumn("dbo.Patients", "StreetAddress", c => c.String(maxLength: 50));
            AlterColumn("dbo.Patients", "LastName", c => c.String(maxLength: 50));
            AlterColumn("dbo.Patients", "SSN", c => c.String(maxLength: 11, fixedLength: true, unicode: false));
        }
    }
}
