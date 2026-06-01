using System.ComponentModel.DataAnnotations;

namespace AblePlusAdmin.Models
{
    public class PendingBusinessRequest
    {
        public Guid Id { get; set; }
        public string? FullName { get; set; }
        public string? Username { get; set; }
        public string? Email { get; set; }
        public string? Location { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

        public string? BusinessImgsUrl { get; set; }
        public string? CommercialRegisterUrl { get; set; }
        public string? IdImgUrl { get; set; }

        public string? Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public Guid? AuthUserId { get; set; }
    }
}