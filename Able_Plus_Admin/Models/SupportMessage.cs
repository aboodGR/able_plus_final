namespace AblePlusAdmin.Models
{
    public class SupportMessage
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string? Message { get; set; }
        public string? Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public string? AdminReply { get; set; }
    }
}