namespace PaceUp.Application.DTOs.Authentication;

public record ResetPasswordRequest(
    string Token,
    string NewPassword);