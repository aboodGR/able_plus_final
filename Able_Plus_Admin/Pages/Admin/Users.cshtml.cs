using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using AblePlusAdmin.Data;
using AblePlusAdmin.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using System.Data;
using System.Net;
using System.Net.Http.Headers;

namespace AblePlusAdmin.Pages.Admin
{
    public class UsersModel : PageModel
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IHttpClientFactory _httpClientFactory;

        public UsersModel(
            AppDbContext context,
            IConfiguration configuration,
            IHttpClientFactory httpClientFactory)
        {
            _context = context;
            _configuration = configuration;
            _httpClientFactory = httpClientFactory;
        }

        public List<Tutor> Tutors { get; set; } = new();
        public List<Business> Businesses { get; set; } = new();
        public List<Charity> Charities { get; set; } = new();
        public List<Client> Clients { get; set; } = new();

        public async Task OnGetAsync()
        {
            Clients = await _context.Clients.ToListAsync();
            Tutors = await _context.Tutors.ToListAsync();
            Businesses = await _context.Businesses.ToListAsync();
            Charities = await _context.Charities.ToListAsync();
        }

        public async Task<IActionResult> OnPostDeleteAsync(Guid id, string type)
        {
            string roleSingular;
            string rolePlural;
            string roleIdColumn;

            switch (type)
            {
                case "client":
                    roleSingular = "client";
                    rolePlural = "clients";
                    roleIdColumn = "client_id";
                    break;
                case "tutor":
                    roleSingular = "tutor";
                    rolePlural = "tutors";
                    roleIdColumn = "tutor_id";
                    break;
                case "business":
                    roleSingular = "business";
                    rolePlural = "businesses";
                    roleIdColumn = "business_id";
                    break;
                case "charity":
                    roleSingular = "charity";
                    rolePlural = "charities";
                    roleIdColumn = "charity_id";
                    break;
                default:
                    return RedirectToPage();
            }

            Guid? authUserId = null;
            string? userEmail = null;

            if (type == "client")
            {
                var u = await _context.Clients.FindAsync(id);
                if (u == null) return RedirectToPage();
                authUserId = u.AuthUserId;
                userEmail = u.Email;
            }
            else if (type == "tutor")
            {
                var u = await _context.Tutors.FindAsync(id);
                if (u == null) return RedirectToPage();
                authUserId = u.AuthUserId;
                userEmail = u.Email;
            }
            else if (type == "business")
            {
                var u = await _context.Businesses.FindAsync(id);
                if (u == null) return RedirectToPage();
                authUserId = u.AuthUserId;
                userEmail = u.Email;
            }
            else if (type == "charity")
            {
                var u = await _context.Charities.FindAsync(id);
                if (u == null) return RedirectToPage();
                authUserId = u.AuthUserId;
                userEmail = u.Email;
            }

            if (!authUserId.HasValue)
            {
                ModelState.AddModelError(string.Empty,
                    "This user does not have auth_user_id, so Supabase Auth cannot be deleted.");
                await OnGetAsync();
                return Page();
            }

            string idText = id.ToString();
            string authUserIdText = authUserId.Value.ToString();

            using var tx = await _context.Database.BeginTransactionAsync();

            try
            {
                // جلب أسماء الجداول مرة واحدة
                var tables = await GetExistingTablesAsync(tx);

                // حذف كل البيانات المرتبطة
                await Del(tables, "media",
                    $"DELETE FROM media WHERE post_id IN (SELECT id FROM posts WHERE {roleIdColumn}::text = {{0}})",
                    idText);

                await Del(tables, "media",
                    $"DELETE FROM media WHERE {roleIdColumn}::text = {{0}}",
                    idText);

                await Del(tables, "post_likes",
                    $"DELETE FROM post_likes WHERE {roleIdColumn}::text = {{0}}",
                    idText);

                await Del(tables, "post_likes",
                    $"DELETE FROM post_likes WHERE post_id IN (SELECT id FROM posts WHERE {roleIdColumn}::text = {{0}})",
                    idText);

                await Del(tables, "post_comments",
                    $"DELETE FROM post_comments WHERE {roleIdColumn}::text = {{0}}",
                    idText);

                await Del(tables, "post_comments",
                    $"DELETE FROM post_comments WHERE post_id IN (SELECT id FROM posts WHERE {roleIdColumn}::text = {{0}})",
                    idText);

                await Del(tables, "post_reports",
                    "DELETE FROM post_reports WHERE reported_by::text = {0}",
                    idText);

                await Del(tables, "post_reports",
                    $"DELETE FROM post_reports WHERE post_id IN (SELECT id FROM posts WHERE {roleIdColumn}::text = {{0}})",
                    idText);

                await Del(tables, "posts",
                    $"DELETE FROM posts WHERE {roleIdColumn}::text = {{0}}",
                    idText);

                await Del(tables, "community_posts",
                    "DELETE FROM community_posts WHERE account_id::text = {0} AND lower(account_type) IN ({1}, {2})",
                    idText, roleSingular, rolePlural);

                await Del(tables, "community_posts",
                    "DELETE FROM community_posts WHERE user_id::text = {0}",
                    authUserIdText);

                if (type == "client")
                    await Del(tables, "follows",
                        "DELETE FROM follows WHERE follower_client_id::text = {0} OR followed_client_id::text = {0}",
                        idText);
                else if (type == "tutor")
                    await Del(tables, "follows",
                        "DELETE FROM follows WHERE followed_tutor_id::text = {0}",
                        idText);
                else if (type == "business")
                    await Del(tables, "follows",
                        "DELETE FROM follows WHERE followed_business_id::text = {0}",
                        idText);
                else if (type == "charity")
                    await Del(tables, "follows",
                        "DELETE FROM follows WHERE followed_charity_id::text = {0}",
                        idText);

                await Del(tables, "user_reports",
                    "DELETE FROM user_reports WHERE reported_by::text = {0}",
                    idText);

                await Del(tables, "user_reports",
                    "DELETE FROM user_reports WHERE reported_user_id::text = {0}",
                    idText);

                if (type == "client")
                {
                    await Del(tables, "business_ratings",
                        "DELETE FROM business_ratings WHERE client_id::text = {0}", idText);
                    await Del(tables, "tutor_ratings",
                        "DELETE FROM tutor_ratings WHERE client_id::text = {0}", idText);
                    await Del(tables, "charity_ratings",
                        "DELETE FROM charity_ratings WHERE client_id::text = {0}", idText);
                }
                else if (type == "business")
                    await Del(tables, "business_ratings",
                        "DELETE FROM business_ratings WHERE business_id::text = {0}", idText);
                else if (type == "tutor")
                    await Del(tables, "tutor_ratings",
                        "DELETE FROM tutor_ratings WHERE tutor_id::text = {0}", idText);
                else if (type == "charity")
                    await Del(tables, "charity_ratings",
                        "DELETE FROM charity_ratings WHERE charity_id::text = {0}", idText);

                await Del(tables, "messages",
                    "DELETE FROM messages WHERE sender_id::text = {0} AND sender_type = {1}",
                    idText, roleSingular);

                await Del(tables, "conversations",
                    "DELETE FROM conversations WHERE " +
                    "(participant_a_id::text = {0} AND participant_a_type = {1}) OR " +
                    "(participant_b_id::text = {0} AND participant_b_type = {1})",
                    idText, roleSingular);

                await Del(tables, "user_blocks",
                    "DELETE FROM user_blocks WHERE " +
                    "(blocker_id::text = {0} AND blocker_type = {1}) OR " +
                    "(blocked_id::text = {0} AND blocked_type = {1})",
                    idText, roleSingular);

                await Del(tables, "notifications",
                    "DELETE FROM notifications WHERE receiver_id::text = {0} OR related_user_id::text = {0}",
                    authUserIdText);

                await Del(tables, "support_messages",
                    "DELETE FROM support_messages WHERE user_id::text = {0}",
                    authUserIdText);

                await Del(tables, "user_preferences",
                    "DELETE FROM user_preferences WHERE user_id::text = {0}",
                    authUserIdText);

                await Del(tables, "profiles",
                    $"DELETE FROM profiles WHERE {roleIdColumn}::text = {{0}}",
                    idText);

                await Del(tables, "admin_requests",
                    $"DELETE FROM admin_requests WHERE {roleIdColumn}::text = {{0}}",
                    idText);

                if (!string.IsNullOrWhiteSpace(userEmail))
                {
                    await Del(tables, "pending_tutor_requests",
                        "DELETE FROM pending_tutor_requests WHERE email = {0}", userEmail);
                    await Del(tables, "pending_business_requests",
                        "DELETE FROM pending_business_requests WHERE email = {0}", userEmail);
                    await Del(tables, "pending_charity_requests",
                        "DELETE FROM pending_charity_requests WHERE email = {0}", userEmail);
                }

                await Del(tables, "pending_tutor_requests",
                    "DELETE FROM pending_tutor_requests WHERE auth_user_id::text = {0}", authUserIdText);
                await Del(tables, "pending_business_requests",
                    "DELETE FROM pending_business_requests WHERE auth_user_id::text = {0}", authUserIdText);
                await Del(tables, "pending_charity_requests",
                    "DELETE FROM pending_charity_requests WHERE auth_user_id::text = {0}", authUserIdText);

                // حذف السجل الرئيسي
                if (type == "client")
                {
                    var u = await _context.Clients.FindAsync(id);
                    if (u != null) _context.Clients.Remove(u);
                }
                else if (type == "tutor")
                {
                    var u = await _context.Tutors.FindAsync(id);
                    if (u != null) _context.Tutors.Remove(u);
                }
                else if (type == "business")
                {
                    var u = await _context.Businesses.FindAsync(id);
                    if (u != null) _context.Businesses.Remove(u);
                }
                else if (type == "charity")
                {
                    var u = await _context.Charities.FindAsync(id);
                    if (u != null) _context.Charities.Remove(u);
                }

                await _context.SaveChangesAsync();

                // حذف من Supabase Auth
                var deleteAuthResult = await DeleteSupabaseAuthUserAsync(authUserId.Value);

                if (!deleteAuthResult.Success)
                {
                    await tx.RollbackAsync();
                    ModelState.AddModelError(string.Empty,
                        deleteAuthResult.ErrorMessage ?? "Failed to delete user from Supabase Auth");
                    await OnGetAsync();
                    return Page();
                }

                await tx.CommitAsync();
                return RedirectToPage();
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
        }

        // استعلام واحد يجيب كل الجداول الموجودة
        private async Task<HashSet<string>> GetExistingTablesAsync(IDbContextTransaction tx)
        {
            var connection = _context.Database.GetDbConnection();
            var shouldClose = connection.State != ConnectionState.Open;

            if (shouldClose)
                await connection.OpenAsync();

            try
            {
                using var command = connection.CreateCommand();
                command.Transaction = tx.GetDbTransaction();
                command.CommandText =
                    "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'";

                var tables = new HashSet<string>();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                    tables.Add(reader.GetString(0));

                return tables;
            }
            finally
            {
                if (shouldClose)
                    await connection.CloseAsync();
            }
        }

        // تنفيذ DELETE فقط إذا الجدول موجود
        private async Task Del(HashSet<string> tables, string tableName, string sql, params object[] parameters)
        {
            if (tables.Contains(tableName))
                await _context.Database.ExecuteSqlRawAsync(sql, parameters);
        }

        private async Task<(bool Success, string? ErrorMessage)> DeleteSupabaseAuthUserAsync(Guid authUserId)
        {
            var supabaseUrl = _configuration["Supabase:Url"]?.TrimEnd('/');
            var serviceRoleKey = _configuration["Supabase:ServiceRoleKey"];

            if (string.IsNullOrWhiteSpace(supabaseUrl) || string.IsNullOrWhiteSpace(serviceRoleKey))
                return (false, "Missing Supabase Url or ServiceRoleKey in configuration.");

            var client = _httpClientFactory.CreateClient();
            client.Timeout = TimeSpan.FromSeconds(15);

            try
            {
                using var request = new HttpRequestMessage(
                    HttpMethod.Delete,
                    $"{supabaseUrl}/auth/v1/admin/users/{authUserId}");

                request.Headers.Add("apikey", serviceRoleKey);
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", serviceRoleKey);

                var response = await client.SendAsync(request);

                // نجاح، أو المستخدم مش موجود أصلاً في Auth = نكمل
                if (response.IsSuccessStatusCode || response.StatusCode == HttpStatusCode.NotFound)
                    return (true, null);

                // 504 = Supabase استقبل الطلب بس ما رد بوقت = نكمل
                if ((int)response.StatusCode == 504)
                    return (true, null);

                var body = await response.Content.ReadAsStringAsync();
                return (false, $"Supabase Auth delete failed: {(int)response.StatusCode} {response.ReasonPhrase}. {body}");
            }
            catch (TaskCanceledException)
            {
                // Timeout = نكمل ونعتبره محذوف
                return (true, null);
            }
            catch (Exception ex)
            {
                return (false, $"Supabase Auth request error: {ex.Message}");
            }
        }
    }
}

