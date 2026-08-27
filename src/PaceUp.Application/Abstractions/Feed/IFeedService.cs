using PaceUp.Application.DTOs.Feed;

namespace PaceUp.Application.Abstractions.Feed;

public interface IFeedService
{
    Task<PagedFeedResponse> GetAsync(
        Guid userId,
        FeedRequest request,
        CancellationToken cancellationToken
    );
}