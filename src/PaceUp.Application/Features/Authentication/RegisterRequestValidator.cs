using FluentValidation;
using PaceUp.Application.DTOs.Authentication;

namespace PaceUp.Application.Features.Authentication;

public class RegisterRequestValidator
    : AbstractValidator<RegisterRequest>
{
    public RegisterRequestValidator()
    {
        RuleFor(x => x.Password)
            .NotEmpty()
            .WithMessage("Password is required.");

        RuleFor(x => x.Password)
            .Must(PasswordRules.IsValid)
            .WithMessage(
                "Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one digit, and one special character.");
    }
}