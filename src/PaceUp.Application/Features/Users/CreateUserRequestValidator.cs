using FluentValidation;
using PaceUp.Application.DTOs.Users;

namespace PaceUp.Application.Features.Users;

public class CreateUserRequestValidator
    : AbstractValidator<CreateUserRequest>
{
    public CreateUserRequestValidator()
    {
        RuleFor(x => x.Username)
            .NotEmpty()
            .MaximumLength(50)
            .Matches("^[a-zA-Z0-9_]+$")
            .WithMessage(
                "Username can only contain letters, numbers, and underscores.");
            

        RuleFor(x => x.Email)
            .NotEmpty()
            .EmailAddress()
            .MaximumLength(255);

        RuleFor(x => x.DisplayName)
            .NotEmpty()
            .MaximumLength(100);
    }
}