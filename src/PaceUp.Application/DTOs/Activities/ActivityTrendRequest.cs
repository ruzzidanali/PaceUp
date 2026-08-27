namespace PaceUp.Application.DTOs.Activities;

public record ActivityTrendRequest(
    DateTime? From = null,
    DateTime? To = null,
    string? Type = null,
    string GroupBy = "day");