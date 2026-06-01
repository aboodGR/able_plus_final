namespace AblePlusAdmin.Models
{
    public class SupportTicketMessage
    {
        public Guid Id { get; set; }
        public Guid TicketId { get; set; }
        public string? SenderType { get; set; }
        public Guid? SenderId { get; set; }
        public string? AdminName { get; set; }
        public string? Message { get; set; }
        public DateTime CreatedAt { get; set; }

        public SupportTicket? Ticket { get; set; }
    }
}
