namespace PaceUp.Application.Abstractions.Communication;

public interface IEmailService
{
    Task SendPasswordResetEmailAsync(
        string email,
        string resetToken,
        CancellationToken cancellationToken);

    Task SendEmailVerificationAsync(
        string email,
        string verificationToken,
        CancellationToken cancellationToken);
}