namespace AblePlusAdmin.Models
{
    public class AdminRequest
    {
        public Guid AdminRequestId { get; set; }
        public string? RequestType { get; set; }
        public Guid? ClientId { get; set; }
        public Guid? TutorId { get; set; }
        public Guid? CharityId { get; set; }
        public Guid? BusinessId { get; set; }
        public string? Status { get; set; }
    }
}