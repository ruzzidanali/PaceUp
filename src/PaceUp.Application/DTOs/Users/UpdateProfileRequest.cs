namespace PaceUp.Application.DTOs.Users;

public record UpdateProfileRequest(
    string DisplayName,
    string? Bio);
