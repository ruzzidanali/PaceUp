namespace PaceUp.Application.DTOs.Authentication;

public record ChangePasswordRequest(
    string CurrentPassword,
    string NewPassword);