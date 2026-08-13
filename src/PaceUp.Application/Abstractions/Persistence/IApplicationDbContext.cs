using Microsoft.EntityFrameworkCore;
using PaceUp.Domain.Entities;

namespace PaceUp.Application.Abstractions.Persistence;

public interface IApplicationDbContext
{
    DbSet<User> Users { get; }

    Task<int> SaveChangesAsync(
        CancellationToken cancellationToken = default);
}