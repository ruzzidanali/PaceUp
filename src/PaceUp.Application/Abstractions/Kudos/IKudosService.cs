using PaceUp.Application.DTOs.Kudos;

namespace PaceUp.Application.Abstractions.Kudos;

public interface IKudosService
{
    Task<KudosResponse> GetAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken);

    Task<KudosResponse> GiveAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken);

    Task<KudosResponse> RemoveAsync(
        Guid userId,
        Guid activityId,
        CancellationToken cancellationToken);
}