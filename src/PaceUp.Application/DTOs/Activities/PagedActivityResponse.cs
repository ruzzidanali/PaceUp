namespace PaceUp.Application.DTOs.Activities;

public record PagedActivityResponse(
    IReadOnlyList<ActivityResponse> Items,
    int Page,
    int PageSize,
    int TotalCount,
    int TotalPages);
