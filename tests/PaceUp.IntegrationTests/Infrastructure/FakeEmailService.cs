using PaceUp.Application.Abstractions.Communication;

namespace PaceUp.IntegrationTests.Infrastructure;

public sealed class FakeEmailService : IEmailService
{
    public List<(string Email, string ResetToken)> SentPasswordResetEmails { get; } = [];

    public List<(string Email, string VerificationToken)> SentEmailVerificationEmails { get; } = [];

    public Task SendPasswordResetEmailAsync(
        string email,
        string resetToken,
        CancellationToken cancellationToken)
    {
        SentPasswordResetEmails.Add((email, resetToken));

        return Task.CompletedTask;
    }

    public Task SendEmailVerificationAsync(
        string email,
        string verificationToken,
        CancellationToken cancellationToken)
    {
        SentEmailVerificationEmails.Add((email, verificationToken));

        return Task.CompletedTask;
    }
}