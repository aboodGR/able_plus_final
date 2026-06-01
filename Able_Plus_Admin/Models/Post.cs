namespace AblePlusAdmin.Models
{
    public class Post
    {
        public Guid Id { get; set; }

        public Guid? ClientId { get; set; }
        public Guid? TutorId { get; set; }
        public Guid? BusinessId { get; set; }
        public Guid? CharityId { get; set; }

        public string? Content { get; set; }
        public int Likes { get; set; }
        public int Comments { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}