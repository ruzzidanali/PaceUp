namespace PaceUp.Application.Abstractions.Communication;

public interface IEmailService
{
    Task SendPasswordResetEmailAsync(
        string email,
        string resetToken,
        CancellationToken cancellationToken);
}