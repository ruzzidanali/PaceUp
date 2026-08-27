namespace PaceUp.Application.DTOs.Activities;

public record ActivityListRequest(
    int Page = 1,
    int PageSize = 20,
    string? Type = null,
    DateTime? From = null,
    DateTime? To = null);