namespace PaceUp.Application.DTOs.Streaks;

public record StreakResponse(
    int CurrentStreak,
    int LongestStreak
);