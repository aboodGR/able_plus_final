namespace AblePlusAdmin.Models
{
    public class PostReport
    {
        public Guid Id { get; set; }
        public Guid? PostId { get; set; }
        public Guid ReportedBy { get; set; }
        public string? Message { get; set; }
        public string? Status { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}