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

    protected override void OnModelCreating(
        ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfigurationsFromAssembly(
            typeof(PaceUpDbContext).Assembly);
    }
}