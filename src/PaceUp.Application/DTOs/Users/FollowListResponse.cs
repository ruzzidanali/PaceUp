namespace PaceUp.Application.DTOs.Users;

public record FollowListResponse(
    IReadOnlyList<FollowResponse> Users,
    int TotalCount);