using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ContosoHR.Models
{
    public class LedgerVerification
    {
        public DateTime TimeStamp { get; set; }
        public string DigestLocations { get; set; }
        public string Result { get; set; }
    }
}