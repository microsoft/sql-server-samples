using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ContosoHR.Models
{
    public class AuditEvent
    {
        public DateTime TimeStamp { get; set; }
        public string UserName { get; set; }
        public string Query { get; set; }
    }
}