using PaceUp.Application.DTOs.Routes;

namespace PaceUp.Application.Abstractions.Routes;

public interface IRouteService
{
    Task<RouteResponse?> GetByActivityIdAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken);

    Task<RouteResponse> CreateAsync(
        Guid userId,
        Guid activityId,
        CreateActivityRouteRequest request,
        CancellationToken cancellationToken);
}