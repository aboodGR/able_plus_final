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

            string idText = id.ToString();
            string? authUserIdText = authUserId?.ToString();

            using var tx = await _context.Database.BeginTransactionAsync();

            try
            {
                await DeleteIfTableExistsAsync(
                    "media",
                    $"DELETE FROM media WHERE post_id IN " +
                    $"(SELECT id FROM posts WHERE {roleIdColumn}::text = {{0}})",
                    idText);

                await DeleteIfTableExistsAsync(
                    "media",
                    $"DELETE FROM media WHERE {roleIdColumn}::text = {{0}}",
                    idText);

                await DeleteIfTableExistsAsync(
                    "post_likes",
                    $"DELETE FROM post_likes WHERE {roleIdColumn}::text = {{0}}",
                    idText);

                await DeleteIfTableExistsAsync(
                    "post_likes",
                    $"DELETE FROM post_likes WHERE post_id IN " +
                    $"(SELECT id FROM posts WHERE {roleIdColumn}::text = {{0}})",
                    idText);

                await DeleteIfTableExistsAsync(
                    "post_comments",
                    $"DELETE FROM post_comments WHERE {roleIdColumn}::text = {{0}}",
                    idText);

                await DeleteIfTableExistsAsync(
                    "post_comments",
                    $"DELETE FROM post_comments WHERE post_id IN " +
                    $"(SELECT id FROM posts WHERE {roleIdColumn}::text = {{0}})",
                    idText);

                await DeleteIfTableExistsAsync(
                    "post_reports",
                    "DELETE FROM post_reports WHERE reported_by::text = {0}",
                    idText);

                await DeleteIfTableExistsAsync(
                    "post_reports",
                    $"DELETE FROM post_reports WHERE post_id IN " +
                    $"(SELECT id FROM posts WHERE {roleIdColumn}::text = {{0}})",
                    idText);

                await DeleteIfTableExistsAsync(
                    "posts",
                    $"DELETE FROM posts WHERE {roleIdColumn}::text = {{0}}",
                    idText);

                await DeleteIfTableExistsAsync(
                    "community_posts",
                    "DELETE FROM community_posts WHERE account_id::text = {0} AND lower(account_type) IN ({1}, {2})",
                    idText, roleSingular, rolePlural);

                if (!string.IsNullOrWhiteSpace(authUserIdText))
                {
                    await DeleteIfTableExistsAsync(
                        "community_posts",
                        "DELETE FROM community_posts WHERE user_id::text = {0}",
                        authUserIdText);
                }

                if (type == "client")
                {
                    await DeleteIfTableExistsAsync(
                        "follows",
                        "DELETE FROM follows WHERE follower_client_id::text = {0} OR followed_client_id::text = {0}",
                        idText);
                }
                else if (type == "tutor")
                {
                    await DeleteIfTableExistsAsync(
                        "follows",
                        "DELETE FROM follows WHERE followed_tutor_id::text = {0}",
                        idText);
                }
                else if (type == "business")
                {
                    await DeleteIfTableExistsAsync(
                        "follows",
                        "DELETE FROM follows WHERE followed_business_id::text = {0}",
                        idText);
                }
                else if (type == "charity")
                {
                    await DeleteIfTableExistsAsync(
                        "follows",
                        "DELETE FROM follows WHERE followed_charity_id::text = {0}",
                        idText);
                }

                await DeleteIfTableExistsAsync(
                    "user_reports",
                    "DELETE FROM user_reports WHERE reported_by::text = {0}",
                    idText);

                await DeleteIfTableExistsAsync(
                    "user_reports",
                    "DELETE FROM user_reports WHERE reported_user_id::text = {0}",
                    idText);

                if (type == "client")
                {
                    await DeleteIfTableExistsAsync(
                        "business_ratings",
                        "DELETE FROM business_ratings WHERE client_id::text = {0}",
                        idText);

                    await DeleteIfTableExistsAsync(
                        "tutor_ratings",
                        "DELETE FROM tutor_ratings WHERE client_id::text = {0}",
                        idText);

                    await DeleteIfTableExistsAsync(
                        "charity_ratings",
                        "DELETE FROM charity_ratings WHERE client_id::text = {0}",
                        idText);
                }
                else if (type == "business")
                {
                    await DeleteIfTableExistsAsync(
                        "business_ratings",
                        "DELETE FROM business_ratings WHERE business_id::text = {0}",
                        idText);
                }
                else if (type == "tutor")
                {
                    await DeleteIfTableExistsAsync(
                        "tutor_ratings",
                        "DELETE FROM tutor_ratings WHERE tutor_id::text = {0}",
                        idText);
                }
                else if (type == "charity")
                {
                    await DeleteIfTableExistsAsync(
                        "charity_ratings",
                        "DELETE FROM charity_ratings WHERE charity_id::text = {0}",
                        idText);
                }

                await DeleteIfTableExistsAsync(
                    "messages",
                    "DELETE FROM messages WHERE sender_id::text = {0} AND sender_type = {1}",
                    idText, roleSingular);

                await DeleteIfTableExistsAsync(
                    "conversations",
                    "DELETE FROM conversations WHERE " +
                    "(participant_a_id::text = {0} AND participant_a_type = {1}) OR " +
                    "(participant_b_id::text = {0} AND participant_b_type = {1})",
                    idText, roleSingular);

                await DeleteIfTableExistsAsync(
                    "user_blocks",
                    "DELETE FROM user_blocks WHERE " +
                    "(blocker_id::text = {0} AND blocker_type = {1}) OR " +
                    "(blocked_id::text = {0} AND blocked_type = {1})",
                    idText, roleSingular);

                if (!string.IsNullOrWhiteSpace(authUserIdText))
                {
                    await DeleteIfTableExistsAsync(
                        "notifications",
                        "DELETE FROM notifications WHERE receiver_id::text = {0} OR related_user_id::text = {0}",
                        authUserIdText);

                    await DeleteIfTableExistsAsync(
                        "support_messages",
                        "DELETE FROM support_messages WHERE user_id::text = {0}",
                        authUserIdText);

                    await DeleteIfTableExistsAsync(
                        "user_preferences",
                        "DELETE FROM user_preferences WHERE user_id::text = {0}",
                        authUserIdText);
                }

                await DeleteIfTableExistsAsync(
                    "profiles",
                    $"DELETE FROM profiles WHERE {roleIdColumn}::text = {{0}}",
                    idText);

                await DeleteIfTableExistsAsync(
                    "admin_requests",
                    $"DELETE FROM admin_requests WHERE {roleIdColumn}::text = {{0}}",
                    idText);

                if (!string.IsNullOrWhiteSpace(userEmail))
                {
                    await DeleteIfTableExistsAsync(
                        "pending_tutor_requests",
                        "DELETE FROM pending_tutor_requests WHERE email = {0}",
                        userEmail);

                    await DeleteIfTableExistsAsync(
                        "pending_business_requests",
                        "DELETE FROM pending_business_requests WHERE email = {0}",
                        userEmail);

                    await DeleteIfTableExistsAsync(
                        "pending_charity_requests",
                        "DELETE FROM pending_charity_requests WHERE email = {0}",
                        userEmail);
                }

                if (!string.IsNullOrWhiteSpace(authUserIdText))
                {
                    await DeleteIfTableExistsAsync(
                        "pending_tutor_requests",
                        "DELETE FROM pending_tutor_requests WHERE auth_user_id::text = {0}",
                        authUserIdText);

                    await DeleteIfTableExistsAsync(
                        "pending_business_requests",
                        "DELETE FROM pending_business_requests WHERE auth_user_id::text = {0}",
                        authUserIdText);

                    await DeleteIfTableExistsAsync(
                        "pending_charity_requests",
                        "DELETE FROM pending_charity_requests WHERE auth_user_id::text = {0}",
                        authUserIdText);
                }

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

                // Delete from Authentication / AspNetUsers
                // Delete from Supabase Authentication / auth.users
// Delete from Supabase Authentication / auth.users
if (authUserId.HasValue)
{
    var deleteAuthResult = await DeleteSupabaseAuthUserAsync(authUserId.Value);

    if (!deleteAuthResult.Success)
    {
        await tx.RollbackAsync();

        ModelState.AddModelError(
            string.Empty,
            deleteAuthResult.ErrorMessage ?? "Failed to delete user from Supabase Auth");

        await OnGetAsync();
        return Page();
    }
}
else
{
    await tx.RollbackAsync();

    ModelState.AddModelError(
        string.Empty,
        "This user does not have auth_user_id, so Supabase Auth cannot be deleted.");

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

        private async Task<(bool Success, string? ErrorMessage)> DeleteSupabaseAuthUserAsync(Guid authUserId)
{
    var supabaseUrl = _configuration["Supabase:Url"]?.TrimEnd('/');
    var serviceRoleKey = _configuration["Supabase:ServiceRoleKey"];

    if (string.IsNullOrWhiteSpace(supabaseUrl) ||
        string.IsNullOrWhiteSpace(serviceRoleKey))
    {
        return (false, "Missing Supabase Url or ServiceRoleKey in configuration.");
    }

    var client = _httpClientFactory.CreateClient();

    using var request = new HttpRequestMessage(
        HttpMethod.Delete,
        $"{supabaseUrl}/auth/v1/admin/users/{authUserId}");

    request.Headers.Add("apikey", serviceRoleKey);
    request.Headers.Authorization =
        new AuthenticationHeaderValue("Bearer", serviceRoleKey);

    var response = await client.SendAsync(request);
    var body = await response.Content.ReadAsStringAsync();

    if (response.IsSuccessStatusCode)
    {
        return (true, null);
    }

    if (response.StatusCode == HttpStatusCode.NotFound)
    {
        return (false, $"Supabase Auth user was not found for auth_user_id={authUserId}.");
    }

    return (
        false,
        $"Supabase Auth delete failed: {(int)response.StatusCode} {response.ReasonPhrase}. {body}"
    );
}

        private async Task DeleteIfTableExistsAsync(string tableName, string deleteSql, params object[] parameters)
        {
            if (await TableExistsAsync(tableName))
            {
                await _context.Database.ExecuteSqlRawAsync(deleteSql, parameters);
            }
        }

        private async Task<bool> TableExistsAsync(string tableName)
        {
            var connection = _context.Database.GetDbConnection();
            var shouldClose = connection.State != ConnectionState.Open;

            if (shouldClose)
            {
                await connection.OpenAsync();
            }

            try
            {
                using var command = connection.CreateCommand();

                if (_context.Database.CurrentTransaction != null)
                {
                    command.Transaction = _context.Database.CurrentTransaction.GetDbTransaction();
                }

                command.CommandText =
                    "SELECT EXISTS (" +
                    "SELECT 1 FROM information_schema.tables " +
                    "WHERE table_schema = 'public' AND table_name = @tableName" +
                    ")";

                var parameter = command.CreateParameter();
                parameter.ParameterName = "@tableName";
                parameter.Value = tableName;
                command.Parameters.Add(parameter);

                var result = await command.ExecuteScalarAsync();

                return result is bool exists && exists;
            }
            finally
            {
                if (shouldClose)
                {
                    await connection.CloseAsync();
                }
            }
        }
    }
}