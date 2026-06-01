using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using AblePlusAdmin.Data;
using AblePlusAdmin.Models;
using Microsoft.EntityFrameworkCore;

namespace AblePlusAdmin.Pages.Admin
{
    public class UserReportsModel : PageModel
    {
        private readonly AppDbContext _context;

        public UserReportsModel(AppDbContext context)
        {
            _context = context;
        }

        public List<UserReport> Reports { get; set; } = new();

        public async Task OnGetAsync()
        {
            Reports = await _context.UserReports
                .Where(r => r.Status == "pending")
                .ToListAsync();
        }

        public string GetUserInfo(Guid userId)
        {
            var client = _context.Clients.FirstOrDefault(c => c.Id == userId);
            if (client != null) return $"Client: {client.Username} ({client.Email})";

            var tutor = _context.Tutors.FirstOrDefault(t => t.Id == userId);
            if (tutor != null) return $"Tutor: {tutor.Username} ({tutor.Email})";

            var business = _context.Businesses.FirstOrDefault(b => b.Id == userId);
            if (business != null) return $"Business: {business.Username} ({business.Email})";

            var charity = _context.Charities.FirstOrDefault(c => c.Id == userId);
            if (charity != null) return $"Charity: {charity.Username} ({charity.Email})";

            return $"User deleted ({userId})";
        }
        public async Task<IActionResult> OnPostDismissAsync(Guid reportId)
        {
            var report = await _context.UserReports.FindAsync(reportId);
            if (report != null)
            {
                report.Status = "dismissed";
                await _context.SaveChangesAsync();
            }
            return RedirectToPage();
        }




    }
}