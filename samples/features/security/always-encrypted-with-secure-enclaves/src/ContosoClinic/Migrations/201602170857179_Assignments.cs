namespace ContosoClinic.Migrations
{
    using System;
    using System.Data.Entity.Migrations;

    public partial class Assignments : DbMigration
    {
        public override void Up()
        {
            CreateTable(
                "dbo.ApplicationUserPatients",
                c => new
                    {
                        ApplicationUser_Id = c.String(nullable: false, maxLength: 128),
                        Patient_PatientID = c.Int(nullable: false),
                    })
                .PrimaryKey(t => new { t.ApplicationUser_Id, t.Patient_PatientID })
                .ForeignKey("dbo.AspNetUsers", t => t.ApplicationUser_Id, cascadeDelete: true)
                .ForeignKey("dbo.Patients", t => t.Patient_PatientID, cascadeDelete: true)
                .Index(t => t.ApplicationUser_Id)
                .Index(t => t.Patient_PatientID);

        }

        public override void Down()
        {
            DropForeignKey("dbo.ApplicationUserPatients", "Patient_PatientID", "dbo.Patients");
            DropForeignKey("dbo.ApplicationUserPatients", "ApplicationUser_Id", "dbo.AspNetUsers");
            DropIndex("dbo.ApplicationUserPatients", new[] { "Patient_PatientID" });
            DropIndex("dbo.ApplicationUserPatients", new[] { "ApplicationUser_Id" });
            DropTable("dbo.ApplicationUserPatients");
        }
    }
}
