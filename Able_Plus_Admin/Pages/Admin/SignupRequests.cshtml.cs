using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using AblePlusAdmin.Data;
using AblePlusAdmin.Models;
using Microsoft.EntityFrameworkCore;

namespace AblePlusAdmin.Pages.Admin
{
    public class SignupRequestsModel : PageModel
    {
        private readonly AppDbContext _context;

        public SignupRequestsModel(AppDbContext context)
        {
            _context = context;
        }

        public List<PendingTutorRequest> TutorRequests { get; set; } = new();
        public List<PendingBusinessRequest> BusinessRequests { get; set; } = new();
        public List<PendingCharityRequest> CharityRequests { get; set; } = new();

        public async Task OnGetAsync()
        {
            TutorRequests = await _context.PendingTutorRequests
                .Where(r => r.Status == "pending")
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            BusinessRequests = await _context.PendingBusinessRequests
                .Where(r => r.Status == "pending")
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            CharityRequests = await _context.PendingCharityRequests
                .Where(r => r.Status == "pending")
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();
        }

        public async Task<IActionResult> OnPostApproveTutorAsync(Guid id)
        {
            var req = await _context.PendingTutorRequests.FindAsync(id);
            if (req == null) return RedirectToPage();

            var tutorId = req.AuthUserId ?? req.Id;

            var tutor = await _context.Tutors.FindAsync(tutorId);
            if (tutor == null)
            {
                tutor = new Tutor
                {
                    Id = tutorId,
                    AuthUserId = tutorId
                };

                _context.Tutors.Add(tutor);
            }

            tutor.FullName = req.FullName;
            tutor.Username = req.Username;
            tutor.Email = req.Email;
            tutor.AuthUserId = tutorId;

            tutor.Bio = req.Bio;
            tutor.Subject = req.Subject;
            tutor.Location = NormalizeLocation(req.Location, req.Latitude, req.Longitude);
            tutor.Latitude = req.Latitude;
            tutor.Longitude = req.Longitude;

            await _context.SaveChangesAsync();

            await AddMediaIfMissingAsync(
                tutorId,
                "tutor",
                req.CertificateUrl,
                "document",
                "certificate_prove"
            );

            await AddMediaIfMissingAsync(
                tutorId,
                "tutor",
                req.CvUrl,
                "document",
                "cv"
            );

            await AddMediaIfMissingAsync(
                tutorId,
                "tutor",
                req.IdImgUrl,
                "image",
                "id_img"
            );

            req.Status = "approved";
            await _context.SaveChangesAsync();

            return RedirectToPage();
        }

        public async Task<IActionResult> OnPostDeclineTutorAsync(Guid id)
        {
            var req = await _context.PendingTutorRequests.FindAsync(id);

            if (req != null)
            {
                req.Status = "declined";
                await _context.SaveChangesAsync();
            }

            return RedirectToPage();
        }

        public async Task<IActionResult> OnPostApproveBusinessAsync(Guid id)
        {
            var req = await _context.PendingBusinessRequests.FindAsync(id);
            if (req == null) return RedirectToPage();

            var businessId = req.AuthUserId ?? req.Id;

            var business = await _context.Businesses.FindAsync(businessId);
            if (business == null)
            {
                business = new Business
                {
                    Id = businessId,
                    AuthUserId = businessId
                };

                _context.Businesses.Add(business);
            }

            business.FullName = req.FullName;
            business.Username = req.Username;
            business.Email = req.Email;
            business.Location = req.Location;
            business.Latitude = req.Latitude;
            business.Longitude = req.Longitude;
            business.AuthUserId = businessId;

            foreach (var imageUrl in SplitUrls(req.BusinessImgsUrl))
            {
                await AddMediaIfMissingAsync(
                    businessId,
                    "business",
                    imageUrl,
                    "image",
                    "business_img"
                );
            }

            await AddMediaIfMissingAsync(
                businessId,
                "business",
                req.CommercialRegisterUrl,
                "document",
                "commercial_register"
            );

            await AddMediaIfMissingAsync(
                businessId,
                "business",
                req.IdImgUrl,
                "image",
                "id_img"
            );

            req.Status = "approved";
            await _context.SaveChangesAsync();

            return RedirectToPage();
        }

        public async Task<IActionResult> OnPostDeclineBusinessAsync(Guid id)
        {
            var req = await _context.PendingBusinessRequests.FindAsync(id);

            if (req != null)
            {
                req.Status = "declined";
                await _context.SaveChangesAsync();
            }

            return RedirectToPage();
        }

        public async Task<IActionResult> OnPostApproveCharityAsync(Guid id)
        {
            var req = await _context.PendingCharityRequests.FindAsync(id);
            if (req == null) return RedirectToPage();

            var charityId = req.AuthUserId ?? req.Id;

            var charity = await _context.Charities.FindAsync(charityId);
            if (charity == null)
            {
                charity = new Charity
                {
                    Id = charityId,
                    AuthUserId = charityId
                };

                _context.Charities.Add(charity);
            }

            charity.FullName = req.FullName;
            charity.Username = req.Username;
            charity.Email = req.Email;
            charity.CharityName = req.CharityName;
            charity.Location = req.Location;
            charity.Latitude = req.Latitude;
            charity.Longitude = req.Longitude;
            charity.AuthUserId = charityId;

            await AddMediaIfMissingAsync(
                charityId,
                "charity",
                req.CharityProveUrl,
                "document",
                "charity_proof"
            );

            await AddMediaIfMissingAsync(
                charityId,
                "charity",
                req.IdImgUrl,
                "image",
                "id_img"
            );

            req.Status = "approved";
            await _context.SaveChangesAsync();

            return RedirectToPage();
        }

        public async Task<IActionResult> OnPostDeclineCharityAsync(Guid id)
        {
            var req = await _context.PendingCharityRequests.FindAsync(id);

            if (req != null)
            {
                req.Status = "declined";
                await _context.SaveChangesAsync();
            }

            return RedirectToPage();
        }

        public static IReadOnlyList<string> SplitUrls(string? urls)
        {
            if (string.IsNullOrWhiteSpace(urls))
                return Array.Empty<string>();

            return urls
                .Split(
                    new[] { "\r\n", "\n", ",", ";" },
                    StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries
                )
                .Where(url => !string.IsNullOrWhiteSpace(url))
                .ToList();
        }

        private static string? NormalizeSubjects(string? subject)
        {
            if (string.IsNullOrWhiteSpace(subject))
                return null;

            return string.Join(", ",
                subject
                    .Split(
                        new[] { "\r\n", "\n", ",", ";" },
                        StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries
                    )
                    .Where(s => !string.IsNullOrWhiteSpace(s))
            );
        }

        private static string? NormalizeLocation(string? location, double? latitude, double? longitude)
        {
            if (!string.IsNullOrWhiteSpace(location))
                return location.Trim();

            if (latitude.HasValue && longitude.HasValue)
                return $"{latitude.Value},{longitude.Value}";

            return null;
        }

        private async Task AddMediaIfMissingAsync(
            Guid ownerId,
            string ownerType,
            string? fileUrl,
            string mediaType,
            string category)
        {
            if (string.IsNullOrWhiteSpace(fileUrl))
                return;

            var existingMedia = _context.Media.Where(m =>
                m.FileUrl == fileUrl &&
                m.Category == category);

            existingMedia = ownerType switch
            {
                "tutor" => existingMedia.Where(m => m.TutorId == ownerId),
                "business" => existingMedia.Where(m => m.BusinessId == ownerId),
                "charity" => existingMedia.Where(m => m.CharityId == ownerId),
                _ => existingMedia.Where(m => false)
            };

            if (await existingMedia.AnyAsync())
                return;

            var media = new Media
            {
                FileUrl = fileUrl,
                FileType = GetFileExtension(fileUrl),
                MediaType = mediaType,
                Category = category
            };

            switch (ownerType)
            {
                case "tutor":
                    media.TutorId = ownerId;
                    break;

                case "business":
                    media.BusinessId = ownerId;
                    break;

                case "charity":
                    media.CharityId = ownerId;
                    break;
            }

            _context.Media.Add(media);
        }

        private static string GetFileExtension(string fileUrl)
        {
            try
            {
                var path = Uri.TryCreate(fileUrl, UriKind.Absolute, out var uri)
                    ? uri.AbsolutePath
                    : fileUrl;

                var extension = Path.GetExtension(path)?.TrimStart('.');

                return string.IsNullOrWhiteSpace(extension)
                    ? "file"
                    : extension.ToLowerInvariant();
            }
            catch
            {
                return "file";
            }
        }
    }
}