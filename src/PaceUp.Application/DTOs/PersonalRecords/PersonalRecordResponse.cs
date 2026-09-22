namespace PaceUp.Application.DTOs.PersonalRecords;

public record PersonalRecordResponse(
    double? LongestDistanceKm,
    int? LongestDurationSeconds,
    double? FastestSpeedKmh,
    double? FastestPaceSecondsPerKm,
    int? MostCalories);