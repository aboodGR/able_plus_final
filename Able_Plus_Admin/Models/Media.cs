namespace AblePlusAdmin.Models
{
    public class Media
    {
        public Guid Id { get; set; }
        public Guid? PostId { get; set; }

        public Guid? ClientId { get; set; }
        public Guid? TutorId { get; set; }
        public Guid? BusinessId { get; set; }
        public Guid? CharityId { get; set; }

        public string? FileUrl { get; set; }
        public string? FileType { get; set; }
        public string? MediaType { get; set; }
        public string? Category { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}