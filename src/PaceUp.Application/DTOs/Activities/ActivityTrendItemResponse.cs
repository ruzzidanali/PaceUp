namespace PaceUp.Application.DTOs.Activities;

public record ActivityTrendResponse(
    DateTime? From,
    DateTime? To,
    string? Type,
    string GroupBy,
    IReadOnlyList<ActivityTrendItemResponse> Items);