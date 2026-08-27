using Microsoft.EntityFrameworkCore;
using PaceUp.Application.Abstractions.Feed;
using PaceUp.Application.Abstractions.Persistence;
using PaceUp.Application.DTOs.Feed;

namespace PaceUp.Application.Features.Feed;

public class FeedService : IFeedService
{
    private readonly IApplicationDbContext _dbContext;

    public FeedService(
        IApplicationDbContext dbContext
    )
    {
        _dbContext = dbContext;
    }

    public async Task<PagedFeedResponse> GetAsync(
        Guid userId,
        FeedRequest request,
        CancellationToken cancellationToken
    )
    {
        var page =
            Math.Max(request.Page, 1);

        var pageSize =
            Math.Clamp(request.PageSize, 1, 100);

        var followingIds =
            _dbContext.Follows
                .Where(x => x.FollowerId == userId)
                .Select(x => x.FollowingId);

        var query =
            _dbContext.Activities
                .AsNoTracking()
                .Where(
                    x => x.UserId == userId ||
                        followingIds.Contains(x.UserId));
        
        var totalCount =
            await query.CountAsync(
                cancellationToken);
        
        var activities = 
            await query
                .OrderByDescending(x => x.StartedAt)
                .ThenByDescending(x => x.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(
                    x => new FeedActivityResponse(
                        x.Id,
                        x.UserId,
                        x.User.Username,
                        x.User.DisplayName,
                        x.User.ProfileImageUrl,
                        x.Type,
                        x.Distance,
                        x.DurationSeconds,
                        x.Calories,
                        x.StartedAt,
                        x.CreatedAt))
                    .ToListAsync(cancellationToken);
        
        var totalPages =
            totalCount == 0
                ? 0
                : (int)Math.Ceiling(
                    totalCount / (double)pageSize);
                

        return new PagedFeedResponse(
            activities,
            page,
            pageSize,
            totalCount,
            totalPages
        );
    }
}