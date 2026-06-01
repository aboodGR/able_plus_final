using System.ComponentModel.DataAnnotations;

namespace AblePlusAdmin.Models
{
    public class Client
    {
        public Guid Id { get; set; }
        public string? FullName { get; set; }
        public string? Username { get; set; }
        public string? Email { get; set; }
        public Guid? AuthUserId { get; set; }
    }
}