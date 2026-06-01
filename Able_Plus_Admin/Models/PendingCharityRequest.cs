using System.ComponentModel.DataAnnotations;

namespace AblePlusAdmin.Models
{
    public class PendingCharityRequest
    {
        public Guid Id { get; set; }
        public string? FullName { get; set; }
        public string? Username { get; set; }
        public string? Email { get; set; }
        public string? CharityName { get; set; }
        public string? Location { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

        public string? CharityProveUrl { get; set; }
        public string? IdImgUrl { get; set; }

        public string? Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public Guid? AuthUserId { get; set; }
    }
}