using PaceUp.Application.DTOs.Dashboard;

namespace PaceUp.Application.Abstractions.Dashboard;

public interface IDashboardService
{
    Task<DashboardResponse> GetAsync(
        Guid userId,
        CancellationToken cancellationToken);
}