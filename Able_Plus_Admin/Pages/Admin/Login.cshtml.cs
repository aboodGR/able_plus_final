using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using AblePlusAdmin.Data;
using Microsoft.EntityFrameworkCore;

namespace AblePlusAdmin.Pages.Admin
{
    public class LoginModel : PageModel
    {
        private readonly AppDbContext _context;

        public LoginModel(AppDbContext context)
        {
            _context = context;
        }

        [BindProperty]
        public string Email { get; set; }

        [BindProperty]
        public string Password { get; set; }

        public string ErrorMessage { get; set; }

        public async Task<IActionResult> OnPostAsync()
        {
            var admin = await _context.Admins
                .FirstOrDefaultAsync(a => a.Email == Email && a.Password == Password);

            if (admin == null)
            {
                ErrorMessage = "Invalid login";
                return Page();
            }

            return RedirectToPage("/Admin/Dashboard");
        }
    }
}