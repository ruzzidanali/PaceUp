using PaceUp.Application.DTOs.Activities;

namespace PaceUp.Application.Abstractions.Activities;

public interface IActivityService
{
    Task<ActivityResponse> CreateAsync(
        Guid userId,
        CreateActivityRequest request,
        CancellationToken cancellationToken);

    Task<ActivityResponse?> GetByIdAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken);

    Task<PagedActivityResponse> GetUserActivitiesAsync(
        Guid userId,
        ActivityListRequest request,
        CancellationToken cancellationToken);

    Task<ActivityStatsResponse> GetStatsAsync(
        Guid userId,
        ActivityListRequest request,
        CancellationToken cancellationToken);

    Task<ActivityResponse?> UpdateAsync(
        Guid userId,
        Guid activityId,
        UpdateActivityRequest request,
        CancellationToken cancellationToken);

    Task<bool> DeleteAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken);

    Task<ActivityTrendResponse> GetTrendsAsync(
        Guid userId,
        ActivityTrendRequest request,
        CancellationToken cancellationToken);
}