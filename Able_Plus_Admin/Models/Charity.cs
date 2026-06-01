using System.ComponentModel.DataAnnotations;

namespace AblePlusAdmin.Models
{
    public class Charity
    {
        
        public Guid Id { get; set; }
        public string? FullName { get; set; } 
        public string? Username { get; set; }
        public string? Email { get; set; }
        public string? CharityName { get; set; }
        public string? Location { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public Guid? AuthUserId { get; set; }
        
    }
}