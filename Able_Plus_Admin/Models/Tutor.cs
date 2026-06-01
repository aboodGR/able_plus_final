using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;

namespace AblePlusAdmin.Models
{
    public class Tutor
    {
        public Guid Id { get; set; }
        public string? FullName { get; set; }
        public string? Username { get; set; }
        public string? Email { get; set; }
        public Guid? AuthUserId { get; set; }
        public string? Bio { get; set; }
        public string[]? Subject { get; set; }
        public string? Location { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
    }
}