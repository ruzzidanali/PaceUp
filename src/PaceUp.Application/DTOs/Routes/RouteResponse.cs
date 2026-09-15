namespace PaceUp.Application.DTOs.Routes;

public record RouteResponse(
    Guid ActivityId,
    IReadOnlyList<ActivityPointResponse> Points);
