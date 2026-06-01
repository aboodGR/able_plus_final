using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using AblePlusAdmin.Models;

namespace AblePlusAdmin.Data
{
    public class AppDbContext : IdentityDbContext<IdentityUser>
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options)
        {
        }

        public DbSet<Admin> Admins { get; set; }
        public DbSet<AdminRequest> AdminRequests { get; set; }
        public DbSet<Tutor> Tutors { get; set; }
        public DbSet<Business> Businesses { get; set; }
        public DbSet<Charity> Charities { get; set; }
        public DbSet<Media> Media { get; set; }
        public DbSet<Client> Clients { get; set; }
        public DbSet<Post> Posts { get; set; }
        public DbSet<PostReport> PostReports { get; set; }
        public DbSet<UserReport> UserReports { get; set; }
        public DbSet<SupportMessage> SupportMessages { get; set; }
        public DbSet<SupportTicket> SupportTickets { get; set; }
        public DbSet<SupportTicketMessage> SupportTicketMessages { get; set; }
        public DbSet<PendingTutorRequest> PendingTutorRequests { get; set; }
        public DbSet<PendingBusinessRequest> PendingBusinessRequests { get; set; }
        public DbSet<PendingCharityRequest> PendingCharityRequests { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Admin
            modelBuilder.Entity<Admin>().ToTable("admins");
            modelBuilder.Entity<Admin>().HasKey(a => a.Id);
            modelBuilder.Entity<Admin>().Property(a => a.Id).HasColumnName("id");
            modelBuilder.Entity<Admin>().Property(a => a.Email).HasColumnName("email");
            modelBuilder.Entity<Admin>().Property(a => a.Password).HasColumnName("password");

            // AdminRequest
            modelBuilder.Entity<AdminRequest>().ToTable("admin_requests");
            modelBuilder.Entity<AdminRequest>().HasKey(a => a.AdminRequestId);
            modelBuilder.Entity<AdminRequest>().Property(a => a.AdminRequestId).HasColumnName("admin_request_id");
            modelBuilder.Entity<AdminRequest>().Property(a => a.RequestType).HasColumnName("request_type");
            modelBuilder.Entity<AdminRequest>().Property(a => a.ClientId).HasColumnName("client_id");
            modelBuilder.Entity<AdminRequest>().Property(a => a.TutorId).HasColumnName("tutor_id");
            modelBuilder.Entity<AdminRequest>().Property(a => a.CharityId).HasColumnName("charity_id");
            modelBuilder.Entity<AdminRequest>().Property(a => a.BusinessId).HasColumnName("business_id");
            modelBuilder.Entity<AdminRequest>().Property(a => a.Status).HasColumnName("status");

            // Tutors
            modelBuilder.Entity<Tutor>().ToTable("tutors");
            modelBuilder.Entity<Tutor>().HasKey(t => t.Id);
            modelBuilder.Entity<Tutor>().Property(t => t.Id).HasColumnName("id");
            modelBuilder.Entity<Tutor>().Property(t => t.FullName).HasColumnName("full_name");
            modelBuilder.Entity<Tutor>().Property(t => t.Username).HasColumnName("username");
            modelBuilder.Entity<Tutor>().Property(t => t.Email).HasColumnName("email");
            modelBuilder.Entity<Tutor>().Property(t => t.AuthUserId).HasColumnName("auth_user_id");
            modelBuilder.Entity<Tutor>().Property(t => t.Bio).HasColumnName("bio");
            modelBuilder.Entity<Tutor>().Property(t => t.Subject).HasColumnName("subject");
            modelBuilder.Entity<Tutor>().Property(t => t.Location).HasColumnName("location");
            modelBuilder.Entity<Tutor>().Property(t => t.Latitude).HasColumnName("latitude");
            modelBuilder.Entity<Tutor>().Property(t => t.Longitude).HasColumnName("longitude");

            // Businesses
            modelBuilder.Entity<Business>().ToTable("businesses");
            modelBuilder.Entity<Business>().HasKey(b => b.Id);
            modelBuilder.Entity<Business>().Property(b => b.Id).HasColumnName("id");
            modelBuilder.Entity<Business>().Property(b => b.FullName).HasColumnName("full_name");
            modelBuilder.Entity<Business>().Property(b => b.Username).HasColumnName("username");
            modelBuilder.Entity<Business>().Property(b => b.Email).HasColumnName("email");
            modelBuilder.Entity<Business>().Property(b => b.Location).HasColumnName("location");
            modelBuilder.Entity<Business>().Property(b => b.Latitude).HasColumnName("latitude");
            modelBuilder.Entity<Business>().Property(b => b.Longitude).HasColumnName("longitude");
            modelBuilder.Entity<Business>().Property(b => b.AuthUserId).HasColumnName("auth_user_id");

            // Charities
            modelBuilder.Entity<Charity>().ToTable("charities");
            modelBuilder.Entity<Charity>().HasKey(c => c.Id);
            modelBuilder.Entity<Charity>().Property(c => c.Id).HasColumnName("id");
            modelBuilder.Entity<Charity>().Property(c => c.FullName).HasColumnName("full_name");
            modelBuilder.Entity<Charity>().Property(c => c.Username).HasColumnName("username");
            modelBuilder.Entity<Charity>().Property(c => c.Email).HasColumnName("email");
            modelBuilder.Entity<Charity>().Property(c => c.CharityName).HasColumnName("charity_name");
            modelBuilder.Entity<Charity>().Property(c => c.Location).HasColumnName("location");
            modelBuilder.Entity<Charity>().Property(c => c.Latitude).HasColumnName("latitude");
            modelBuilder.Entity<Charity>().Property(c => c.Longitude).HasColumnName("longitude");
            modelBuilder.Entity<Charity>().Property(c => c.AuthUserId).HasColumnName("auth_user_id");

            // Clients
            modelBuilder.Entity<Client>().ToTable("clients");
            modelBuilder.Entity<Client>().HasKey(c => c.Id);
            modelBuilder.Entity<Client>().Property(c => c.Id).HasColumnName("id");
            modelBuilder.Entity<Client>().Property(c => c.FullName).HasColumnName("full_name");
            modelBuilder.Entity<Client>().Property(c => c.Username).HasColumnName("username");
            modelBuilder.Entity<Client>().Property(c => c.Email).HasColumnName("email");
            modelBuilder.Entity<Client>().Property(c => c.AuthUserId).HasColumnName("auth_user_id");

            // Media
            modelBuilder.Entity<Media>().ToTable("media");
            modelBuilder.Entity<Media>().HasKey(m => m.Id);
            modelBuilder.Entity<Media>().Property(m => m.Id).HasColumnName("id");
            modelBuilder.Entity<Media>().Property(m => m.PostId).HasColumnName("post_id");
            modelBuilder.Entity<Media>().Property(m => m.ClientId).HasColumnName("client_id");
            modelBuilder.Entity<Media>().Property(m => m.TutorId).HasColumnName("tutor_id");
            modelBuilder.Entity<Media>().Property(m => m.BusinessId).HasColumnName("business_id");
            modelBuilder.Entity<Media>().Property(m => m.CharityId).HasColumnName("charity_id");
            modelBuilder.Entity<Media>().Property(m => m.FileUrl).HasColumnName("file_url");
            modelBuilder.Entity<Media>().Property(m => m.FileType).HasColumnName("file_type");
            modelBuilder.Entity<Media>().Property(m => m.MediaType).HasColumnName("media_type");
            modelBuilder.Entity<Media>().Property(m => m.Category).HasColumnName("category");
            modelBuilder.Entity<Media>().Property(m => m.CreatedAt).HasColumnName("created_at");

            // Posts
            modelBuilder.Entity<Post>().ToTable("posts");
            modelBuilder.Entity<Post>().HasKey(p => p.Id);
            modelBuilder.Entity<Post>().Property(p => p.Id).HasColumnName("id");
            modelBuilder.Entity<Post>().Property(p => p.ClientId).HasColumnName("client_id");
            modelBuilder.Entity<Post>().Property(p => p.TutorId).HasColumnName("tutor_id");
            modelBuilder.Entity<Post>().Property(p => p.BusinessId).HasColumnName("business_id");
            modelBuilder.Entity<Post>().Property(p => p.CharityId).HasColumnName("charity_id");
            modelBuilder.Entity<Post>().Property(p => p.Content).HasColumnName("content");
            modelBuilder.Entity<Post>().Property(p => p.Likes).HasColumnName("likes");
            modelBuilder.Entity<Post>().Property(p => p.Comments).HasColumnName("comments");
            modelBuilder.Entity<Post>().Property(p => p.CreatedAt).HasColumnName("created_at");

            // PostReports
            modelBuilder.Entity<PostReport>().ToTable("post_reports");
            modelBuilder.Entity<PostReport>().HasKey(r => r.Id);
            modelBuilder.Entity<PostReport>().Property(r => r.Id).HasColumnName("id");
            modelBuilder.Entity<PostReport>().Property(r => r.PostId).HasColumnName("post_id");
            modelBuilder.Entity<PostReport>().Property(r => r.ReportedBy).HasColumnName("reported_by");
            modelBuilder.Entity<PostReport>().Property(r => r.Message).HasColumnName("message");
            modelBuilder.Entity<PostReport>().Property(r => r.Status).HasColumnName("status");
            modelBuilder.Entity<PostReport>().Property(r => r.CreatedAt).HasColumnName("created_at");

            // UserReports
            modelBuilder.Entity<UserReport>().ToTable("user_reports");
            modelBuilder.Entity<UserReport>().HasKey(r => r.Id);
            modelBuilder.Entity<UserReport>().Property(r => r.Id).HasColumnName("id");
            modelBuilder.Entity<UserReport>().Property(r => r.ReportedUserId).HasColumnName("reported_user_id");
            modelBuilder.Entity<UserReport>().Property(r => r.ReportedBy).HasColumnName("reported_by");
            modelBuilder.Entity<UserReport>().Property(r => r.Message).HasColumnName("message");
            modelBuilder.Entity<UserReport>().Property(r => r.Status).HasColumnName("status");
            modelBuilder.Entity<UserReport>().Property(r => r.CreatedAt).HasColumnName("created_at");

            // SupportMessage
            modelBuilder.Entity<SupportMessage>().ToTable("support_messages");
            modelBuilder.Entity<SupportMessage>().HasKey(s => s.Id);
            modelBuilder.Entity<SupportMessage>().Property(s => s.Id).HasColumnName("id");
            modelBuilder.Entity<SupportMessage>().Property(s => s.UserId).HasColumnName("user_id");
            modelBuilder.Entity<SupportMessage>().Property(s => s.Message).HasColumnName("message");
            modelBuilder.Entity<SupportMessage>().Property(s => s.Status).HasColumnName("status");
            modelBuilder.Entity<SupportMessage>().Property(s => s.CreatedAt).HasColumnName("created_at");
            modelBuilder.Entity<SupportMessage>().Property(s => s.AdminReply).HasColumnName("admin_reply");

            // SupportTicket
            modelBuilder.Entity<SupportTicket>().ToTable("support_tickets");
            modelBuilder.Entity<SupportTicket>().HasKey(t => t.Id);
            modelBuilder.Entity<SupportTicket>().Property(t => t.Id).HasColumnName("id");
            modelBuilder.Entity<SupportTicket>().Property(t => t.UserId).HasColumnName("user_id");
            modelBuilder.Entity<SupportTicket>().Property(t => t.Title).HasColumnName("title");
            modelBuilder.Entity<SupportTicket>().Property(t => t.Category).HasColumnName("category");
            modelBuilder.Entity<SupportTicket>().Property(t => t.Priority).HasColumnName("priority");
            modelBuilder.Entity<SupportTicket>().Property(t => t.Status).HasColumnName("status");
            modelBuilder.Entity<SupportTicket>().Property(t => t.CreatedAt).HasColumnName("created_at");
            modelBuilder.Entity<SupportTicket>().Property(t => t.UpdatedAt).HasColumnName("updated_at");
            modelBuilder.Entity<SupportTicket>().Property(t => t.LastMessageAt).HasColumnName("last_message_at");
            modelBuilder.Entity<SupportTicket>().Property(t => t.ClosedAt).HasColumnName("closed_at");
            modelBuilder.Entity<SupportTicket>().Property(t => t.ClosedBy).HasColumnName("closed_by");

            // SupportTicketMessage
            modelBuilder.Entity<SupportTicketMessage>().ToTable("support_ticket_messages");
            modelBuilder.Entity<SupportTicketMessage>().HasKey(m => m.Id);
            modelBuilder.Entity<SupportTicketMessage>().Property(m => m.Id).HasColumnName("id");
            modelBuilder.Entity<SupportTicketMessage>().Property(m => m.TicketId).HasColumnName("ticket_id");
            modelBuilder.Entity<SupportTicketMessage>().Property(m => m.SenderType).HasColumnName("sender_type");
            modelBuilder.Entity<SupportTicketMessage>().Property(m => m.SenderId).HasColumnName("sender_id");
            modelBuilder.Entity<SupportTicketMessage>().Property(m => m.AdminName).HasColumnName("admin_name");
            modelBuilder.Entity<SupportTicketMessage>().Property(m => m.Message).HasColumnName("message");
            modelBuilder.Entity<SupportTicketMessage>().Property(m => m.CreatedAt).HasColumnName("created_at");

            modelBuilder.Entity<SupportTicket>()
                .HasMany(t => t.Messages)
                .WithOne(m => m.Ticket)
                .HasForeignKey(m => m.TicketId);

            // PendingTutorRequest
            modelBuilder.Entity<PendingTutorRequest>().ToTable("pending_tutor_requests");
            modelBuilder.Entity<PendingTutorRequest>().HasKey(p => p.Id);
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.Id).HasColumnName("id");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.FullName).HasColumnName("full_name");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.Username).HasColumnName("username");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.Email).HasColumnName("email");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.CertificateUrl).HasColumnName("certificate_url");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.CvUrl).HasColumnName("cv_url");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.IdImgUrl).HasColumnName("id_img_url");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.Status).HasColumnName("status");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.CreatedAt).HasColumnName("created_at");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.AuthUserId).HasColumnName("auth_user_id");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.Bio).HasColumnName("bio");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.Subject).HasColumnName("subject");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.Location).HasColumnName("location");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.Latitude).HasColumnName("latitude");
            modelBuilder.Entity<PendingTutorRequest>().Property(p => p.Longitude).HasColumnName("longitude");

            // PendingBusinessRequest
            modelBuilder.Entity<PendingBusinessRequest>().ToTable("pending_business_requests");
            modelBuilder.Entity<PendingBusinessRequest>().HasKey(p => p.Id);
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.Id).HasColumnName("id");
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.FullName).HasColumnName("full_name");
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.Username).HasColumnName("username");
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.Email).HasColumnName("email");
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.Location).HasColumnName("location");
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.BusinessImgsUrl).HasColumnName("business_imgs_url");
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.CommercialRegisterUrl).HasColumnName("commercial_register_url");
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.IdImgUrl).HasColumnName("id_img_url");
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.Status).HasColumnName("status");
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.CreatedAt).HasColumnName("created_at");
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.Latitude).HasColumnName("latitude");
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.Longitude).HasColumnName("longitude");
            modelBuilder.Entity<PendingBusinessRequest>().Property(p => p.AuthUserId).HasColumnName("auth_user_id");

            // PendingCharityRequest
            modelBuilder.Entity<PendingCharityRequest>().ToTable("pending_charity_requests");
            modelBuilder.Entity<PendingCharityRequest>().HasKey(p => p.Id);
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.Id).HasColumnName("id");
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.FullName).HasColumnName("full_name");
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.Username).HasColumnName("username");
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.Email).HasColumnName("email");
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.CharityName).HasColumnName("charity_name");
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.Location).HasColumnName("location");
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.Latitude).HasColumnName("latitude");
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.Longitude).HasColumnName("longitude");
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.CharityProveUrl).HasColumnName("charity_prove_url");
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.IdImgUrl).HasColumnName("id_img_url");
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.Status).HasColumnName("status");
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.CreatedAt).HasColumnName("created_at");
            modelBuilder.Entity<PendingCharityRequest>().Property(p => p.AuthUserId).HasColumnName("auth_user_id");
        }
    }

    public class Admin
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}