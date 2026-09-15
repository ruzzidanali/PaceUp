namespace PaceUp.Application.DTOs.Kudos;

public record KudosResponse(
    Guid ActivityId,
    int KudosCount,
    bool HasGivenKudos);