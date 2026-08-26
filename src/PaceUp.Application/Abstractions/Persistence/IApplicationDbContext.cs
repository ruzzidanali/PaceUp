using Microsoft.EntityFrameworkCore;
using PaceUp.Domain.Entities;

namespace PaceUp.Application.Abstractions.Persistence;

public interface IApplicationDbContext
{
    DbSet<User> Users { get; }

    DbSet<UserIdentity> UserIdentities { get; }

    DbSet<Activity> Activities { get; }

    DbSet<Goal> Goals { get; }

    DbSet<EmailVerificationToken> EmailVerificationTokens { get; }

    DbSet<PasswordResetToken> PasswordResetTokens { get; }

    DbSet<RefreshToken> RefreshTokens { get; }

    DbSet<Follow> Follows { get; }

    Task<int> SaveChangesAsync(
        CancellationToken cancellationToken = default);
}