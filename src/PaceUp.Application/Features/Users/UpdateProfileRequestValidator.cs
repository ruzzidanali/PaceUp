using FluentValidation;
using PaceUp.Application.DTOs.Users;

namespace PaceUp.Application.Features.Users;

public class UpdateProfileRequestValidator
    : AbstractValidator<UpdateProfileRequest>
{
    public UpdateProfileRequestValidator()
    {
        RuleFor(x => x.DisplayName)
            .NotEmpty()
            .WithMessage("Display name is required.")
            .MaximumLength(100)
            .WithMessage("Display name cannot exceed 100 characters.");

        RuleFor(x => x.Bio)
            .MaximumLength(500)
            .When(x => x.Bio is not null)
            .WithMessage("Bio cannot exceed 500 characters.");
    }
}