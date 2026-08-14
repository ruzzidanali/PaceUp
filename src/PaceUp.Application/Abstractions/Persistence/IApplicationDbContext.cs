using Microsoft.EntityFrameworkCore;
using PaceUp.Domain.Entities;

namespace PaceUp.Application.Abstractions.Persistence;

public interface IApplicationDbContext
{
    DbSet<User> Users { get; }

    DbSet<UserIdentity> UserIdentities { get; }

    DbSet<Activity> Activities { get; }

    Task<int> SaveChangesAsync(
        CancellationToken cancellationToken = default);
}