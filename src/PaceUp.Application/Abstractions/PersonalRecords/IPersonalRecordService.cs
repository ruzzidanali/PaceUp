using PaceUp.Application.DTOs.PersonalRecords;

namespace PaceUp.Application.Abstractions.PersonalRecords;

public interface IPersonalRecordService
{
    Task<PersonalRecordResponse> GetAsync(
        Guid userId,
        CancellationToken cancellationToken);
}