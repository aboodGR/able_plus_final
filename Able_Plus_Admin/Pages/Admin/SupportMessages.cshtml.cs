using AblePlusAdmin.Data;
using AblePlusAdmin.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace AblePlusAdmin.Pages.Admin
{
    public class SupportMessagesModel : PageModel
    {
        private readonly AppDbContext _context;

        public SupportMessagesModel(AppDbContext context)
        {
            _context = context;
        }

        public List<SupportTicket> Tickets { get; set; } = new();
        public SupportTicket? SelectedTicket { get; set; }
        public string StatusFilter { get; set; } = "active";

        public async Task OnGetAsync(Guid? ticketId, string? status)
        {
            StatusFilter = string.IsNullOrWhiteSpace(status) ? "active" : status;

            var query = _context.SupportTickets.AsQueryable();

            if (StatusFilter == "active")
            {
                query = query.Where(t => t.Status != "closed");
            }
            else if (StatusFilter == "closed")
            {
                query = query.Where(t => t.Status == "closed");
            }

            Tickets = await query
                .OrderByDescending(t => t.LastMessageAt)
                .ToListAsync();

            if (ticketId.HasValue)
            {
                SelectedTicket = await _context.SupportTickets
                    .FirstOrDefaultAsync(t => t.Id == ticketId.Value);
            }
            else
            {
                SelectedTicket = Tickets.FirstOrDefault();
            }

            if (SelectedTicket != null)
            {
                await _context.Entry(SelectedTicket)
                    .Collection(t => t.Messages)
                    .Query()
                    .OrderBy(m => m.CreatedAt)
                    .LoadAsync();
            }
        }

        public async Task<IActionResult> OnPostReplyAsync(Guid ticketId, string adminMessage, string? status)
        {
            if (string.IsNullOrWhiteSpace(adminMessage))
            {
                return RedirectToPage(new { ticketId, status = status ?? "active" });
            }

            var ticket = await _context.SupportTickets.FindAsync(ticketId);
            if (ticket == null || ticket.Status == "closed")
            {
                return RedirectToPage(new { status = status ?? "active" });
            }

            var now = DateTime.UtcNow;

            _context.SupportTicketMessages.Add(new SupportTicketMessage
            {
                TicketId = ticketId,
                SenderType = "admin",
                AdminName = "Admin",
                Message = adminMessage.Trim(),
                CreatedAt = now
            });

            ticket.Status = "pending_user";
            ticket.UpdatedAt = now;
            ticket.LastMessageAt = now;

            await _context.SaveChangesAsync();

            return RedirectToPage(new { ticketId, status = status ?? "active" });
        }

        public async Task<IActionResult> OnPostCloseAsync(Guid ticketId, string? status)
        {
            var ticket = await _context.SupportTickets.FindAsync(ticketId);
            if (ticket != null)
            {
                var now = DateTime.UtcNow;
                ticket.Status = "closed";
                ticket.ClosedBy = "admin";
                ticket.ClosedAt = now;
                ticket.UpdatedAt = now;
                await _context.SaveChangesAsync();
            }

            return RedirectToPage(new { ticketId, status = "closed" });
        }

        public async Task<IActionResult> OnPostReopenAsync(Guid ticketId, string? status)
        {
            var ticket = await _context.SupportTickets.FindAsync(ticketId);
            if (ticket != null)
            {
                var now = DateTime.UtcNow;
                ticket.Status = "pending_admin";
                ticket.ClosedBy = null;
                ticket.ClosedAt = null;
                ticket.UpdatedAt = now;

                _context.SupportTicketMessages.Add(new SupportTicketMessage
                {
                    TicketId = ticketId,
                    SenderType = "system",
                    AdminName = "System",
                    Message = "Ticket reopened by admin.",
                    CreatedAt = now
                });

                await _context.SaveChangesAsync();
            }

            return RedirectToPage(new { ticketId, status = "active" });
        }

        public async Task<IActionResult> OnPostDeleteAsync(Guid ticketId, string? status)
        {
            var ticket = await _context.SupportTickets.FindAsync(ticketId);
            if (ticket != null)
            {
                _context.SupportTickets.Remove(ticket);
                await _context.SaveChangesAsync();
            }

            return RedirectToPage(new { status = status ?? "active" });
        }

        public string GetUserInfo(Guid authUserId)
        {
            var client = _context.Clients.FirstOrDefault(c => c.AuthUserId == authUserId || c.Id == authUserId);
            if (client != null) return $"Client: {client.Username} ({client.Email})";

            var tutor = _context.Tutors.FirstOrDefault(t => t.AuthUserId == authUserId || t.Id == authUserId);
            if (tutor != null) return $"Tutor: {tutor.Username} ({tutor.Email})";

            var business = _context.Businesses.FirstOrDefault(b => b.AuthUserId == authUserId || b.Id == authUserId);
            if (business != null) return $"Business: {business.Username} ({business.Email})";

            var charity = _context.Charities.FirstOrDefault(c => c.AuthUserId == authUserId || c.Id == authUserId);
            if (charity != null) return $"Charity: {charity.Username} ({charity.Email})";

            return authUserId.ToString();
        }

        public string StatusBadgeClass(string? status)
        {
            return status switch
            {
                "pending_admin" => "badge bg-warning text-dark",
                "pending_user" => "badge bg-info text-dark",
                "closed" => "badge bg-secondary",
                "open" => "badge bg-success",
                _ => "badge bg-light text-dark"
            };
        }
    }
}
