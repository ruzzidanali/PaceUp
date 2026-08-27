namespace PaceUp.Application.DTOs.Feed;

public record PagedFeedResponse(
    IReadOnlyList<FeedActivityResponse> Activities,
    int Page,
    int PageSize,
    int TotalCount,
    int TotalPages
);