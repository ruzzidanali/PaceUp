namespace PaceUp.Application.DTOs.Feed;

public record FeedRequest(
    int Page = 1,
    int PageSize = 20);