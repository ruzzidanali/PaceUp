namespace PaceUp.Application.DTOs.Authentication;

public record RegistrationResponse(
    Guid UserId,
    string Username,
    string Email,
    string DisplayName,
    bool EmailVerificationRequired);
