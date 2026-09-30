using FluentValidation;
using PaceUp.Application.DTOs.Authentication;

namespace PaceUp.Application.Features.Authentication;

public class ResetPasswordRequestValidator
    : AbstractValidator<ResetPasswordRequest>
{
    public ResetPasswordRequestValidator()
    {
        RuleFor(x => x.Token)
            .NotEmpty()
            .WithMessage("Password reset token is required.");

        RuleFor(x => x.NewPassword)
            .NotEmpty()
            .WithMessage("New password is required.");

        RuleFor(x => x.NewPassword)
            .Must(PasswordRules.IsValid)
            .WithMessage(
                "New password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one digit, and one special character.");
    }
}