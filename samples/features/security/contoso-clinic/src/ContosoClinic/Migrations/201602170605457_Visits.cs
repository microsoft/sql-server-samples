namespace ContosoClinic.Migrations
{
    using System;
    using System.Data.Entity.Migrations;

    public partial class Visits : DbMigration
    {
        public override void Up()
        {
            CreateTable(
                "dbo.Visits",
                c => new
                    {
                        VisitID = c.Int(nullable: false, identity: true),
                        PatientID = c.Int(nullable: false),
                        Date = c.DateTime(nullable: false, storeType: "date"),
                        Reason = c.String(maxLength: 4000),
                        Treatment = c.String(maxLength: 4000),
                        FollowUpDate = c.DateTime(storeType: "date"),
                    })
                .PrimaryKey(t => t.VisitID)
                .ForeignKey("dbo.Patients", t => t.PatientID, cascadeDelete: true)
                .Index(t => t.PatientID);

        }

        public override void Down()
        {
            DropForeignKey("dbo.Visits", "PatientID", "dbo.Patients");
            DropIndex("dbo.Visits", new[] { "PatientID" });
            DropTable("dbo.Visits");
        }
    }
}
