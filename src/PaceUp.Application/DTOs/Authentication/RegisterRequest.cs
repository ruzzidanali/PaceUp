namespace PaceUp.Application.DTOs.Authentication;

public record RegisterRequest(
    string Username,
    string Email,
    string DisplayName,
    string Password);