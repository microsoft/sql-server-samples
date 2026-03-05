namespace AssessmentClient.SMO
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading.Tasks;

    using Microsoft.SqlServer.Management.Assessment;
    using Microsoft.SqlServer.Management.Assessment.Checks;
    using Microsoft.SqlServer.Management.Smo;

    public static class Program
    {
        private static async Task Main(string[] args)
        {
            // Connect to a server or a database with SMO
            // https://docs.microsoft.com/en-us/sql/relational-databases/server-management-objects-smo/create-program/connecting-to-an-instance-of-sql-server
            var target = new Server();


            // Use GetAssessmentItem method to obtain
            // a list of available SQL Assessment checks
            IEnumerable<ICheck> checklist = target.GetAssessmentItems();


            // Checks are tagged with strings corresponding to
            // categories like "Performance", "Storage", or "Security"
            var allTags = new SortedSet<string>(checklist.SelectMany(c => c.Tags));

            DisplayCategories(target.Name, allTags);

            while (Prompt(out string? line))
            {
                // Use GetAssessmentResultsList to run assessment
                List<IAssessmentResult> assessmentResults = string.IsNullOrWhiteSpace(line) 
                    ? await target.GetAssessmentResultsList().ConfigureAwait(false)              // all checks
                    : await target.GetAssessmentResultsList(line.Split()).ConfigureAwait(false); // selected checks

                DisplayAssessmentResults(assessmentResults);
            }
        }

        private static void DisplayAssessmentResults(List<IAssessmentResult> assessmentResults)
        {
            // Properties of IAssessmentResult provide
            // recommendation text, help link, etc
            foreach (var result in assessmentResults)
            {
                Console.WriteLine("-------");
                Console.Write("  ");
                Console.WriteLine(result.Message);
                Console.Write("  ");
                Console.WriteLine(result.Check.HelpLink);
            }
        }

        private static bool Prompt(out string? line)
        {
            Console.Write("Enter category (ENTER for all categories, 'exit' to leave) > ");
            line = Console.ReadLine();

            return string.Compare(line, "exit", StringComparison.OrdinalIgnoreCase) != 0;
        }

        private static void DisplayCategories(string targetName, IEnumerable<string> allTags)
        {
            Console.WriteLine($"All categories available for {targetName}:\n");

            foreach (var tag in allTags)
            {
                Console.WriteLine($"  {tag}");
            }
        }
    }
}
