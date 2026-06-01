using System.ComponentModel.DataAnnotations;

namespace AblePlusAdmin.Models
{
    public class PendingTutorRequest
    {
        public Guid Id { get; set; }

        public string FullName { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }

        public string CertificateUrl { get; set; }
        public string CvUrl { get; set; }
        public string IdImgUrl { get; set; }

        public string Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public Guid? AuthUserId { get; set; }
        public string? Bio { get; set; }
        public string[]? Subject { get; set; }
        public string? Location { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
    }
}