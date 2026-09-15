namespace PaceUp.Application.DTOs.Routes;

public record CreateActivityRouteRequest(
    IReadOnlyList<CreateActivityPointRequest> Points);