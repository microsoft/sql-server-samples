using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace SensorModule.Models
{
    public class OnnxModel
    {
        [Key]
        public int Id { get; set; }
        public string Description { get; set; }
        public byte[] Data { get; set; }
    }
}