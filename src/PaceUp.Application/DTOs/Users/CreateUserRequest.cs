namespace PaceUp.Application.DTOs.Users;

public record CreateUserRequest(
    string Username,
    string Email,
    string DisplayName);