namespace PaceUp.Application.DTOs.Leaderboards;

public record LeaderboardEntryResponse(
    int Rank,
    Guid UserId,
    string Username,
    string DisplayName,
    string? ProfileImageUrl,
    double DistanceKm,
    bool IsCurrentUser);