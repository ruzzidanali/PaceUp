using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Domain.Entities;

namespace PaceUp.Infrastructure.Persistence;

public class PaceUpDbContext :
    DbContext,
    IApplicationDbContext
{
    public PaceUpDbContext(
        DbContextOptions<PaceUpDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Activity> Activities => Set<Activity>();

    public DbSet<Goal> Goals => Set<Goal>();

    public DbSet<UserIdentity> UserIdentities =>
        Set<UserIdentity>();

    public DbSet<EmailVerificationToken> EmailVerificationTokens =>
        Set<EmailVerificationToken>();

    public DbSet<PasswordResetToken> PasswordResetTokens =>
        Set<PasswordResetToken>();

    public DbSet<RefreshToken> RefreshTokens =>
        Set<RefreshToken>();

    public DbSet<Follow> Follows =>
        Set<Follow>();

    public DbSet<Notification> Notifications =>
        Set<Notification>();

    public DbSet<Challenge> Challenges =>
        Set<Challenge>();

public DbSet<ChallengeParticipant> ChallengeParticipants =>
        Set<ChallengeParticipant>();

    protected override void OnModelCreating(
        ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfigurationsFromAssembly(
            typeof(PaceUpDbContext).Assembly);
    }
}