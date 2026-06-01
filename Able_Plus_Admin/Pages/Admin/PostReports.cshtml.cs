using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using AblePlusAdmin.Data;
using AblePlusAdmin.Models;
using Microsoft.EntityFrameworkCore;

namespace AblePlusAdmin.Pages.Admin
{
    public class PostReportsModel : PageModel
    {
        private readonly AppDbContext _context;

        public PostReportsModel(AppDbContext context)
        {
            _context = context;
        }

        public List<PostReport> Reports { get; set; } = new();

        public async Task OnGetAsync()
        {
            Reports = await _context.PostReports
                .Where(r => r.Status == "pending")
                .ToListAsync();
        }

        public Post? GetPost(Guid? postId)
        {
            if (postId == null) return null;
            return _context.Posts.FirstOrDefault(p => p.Id == postId);
        }

        public string GetPostOwnerUsername(Post? post)
        {
            if (post == null) return "-";

            if (post.ClientId != null)
                return _context.Clients.FirstOrDefault(c => c.Id == post.ClientId)?.Username ?? "-";

            if (post.TutorId != null)
                return _context.Tutors.FirstOrDefault(t => t.Id == post.TutorId)?.Username ?? "-";

            if (post.BusinessId != null)
                return _context.Businesses.FirstOrDefault(b => b.Id == post.BusinessId)?.Username ?? "-";

            if (post.CharityId != null)
                return _context.Charities.FirstOrDefault(c => c.Id == post.CharityId)?.Username ?? "-";

            return "-";
        }

        public string GetReporterUsername(Guid reporterId)
        {
            var client = _context.Clients.FirstOrDefault(c => c.Id == reporterId);
            if (client != null) return client.Username ?? "-";

            var tutor = _context.Tutors.FirstOrDefault(t => t.Id == reporterId);
            if (tutor != null) return tutor.Username ?? "-";

            var business = _context.Businesses.FirstOrDefault(b => b.Id == reporterId);
            if (business != null) return business.Username ?? "-";

            var charity = _context.Charities.FirstOrDefault(c => c.Id == reporterId);
            if (charity != null) return charity.Username ?? "-";

            return "-";
        }

        public List<Media> GetPostMedia(Guid? postId)
        {
            if (postId == null) return new List<Media>();

            return _context.Media
                .Where(m => m.PostId == postId)
                .ToList();
        }

        public async Task<IActionResult> OnPostDeletePostAsync(Guid reportId, Guid postId)
        {
            
            var mediaRows = _context.Media.Where(m => m.PostId == postId);
            _context.Media.RemoveRange(mediaRows);

            
            var post = await _context.Posts.FindAsync(postId);
            if (post != null) _context.Posts.Remove(post);

            
            var allReportsForPost = _context.PostReports.Where(r => r.PostId == postId);
            foreach (var r in allReportsForPost) r.Status = "resolved";

            await _context.SaveChangesAsync();
            return RedirectToPage();
        }

        public async Task<IActionResult> OnPostDismissAsync(Guid reportId)
        {
            var report = await _context.PostReports.FindAsync(reportId);

            if (report != null)
            {
                report.Status = "dismissed";
                await _context.SaveChangesAsync();
            }

            return RedirectToPage();
        }
    }
}