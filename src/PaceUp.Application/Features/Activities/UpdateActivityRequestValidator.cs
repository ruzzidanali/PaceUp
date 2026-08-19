using FluentValidation;
using PaceUp.Application.DTOs.Activities;
using PaceUp.Domain.Constants;

namespace PaceUp.Application.Features.Activities;

public class UpdateActivityRequestValidator
    : AbstractValidator<UpdateActivityRequest>
{
    public UpdateActivityRequestValidator()
    {
        RuleFor(x => x.Type)
            .NotEmpty()
            .Must(ActivityTypes.IsValid)
            .WithMessage("Activity type is not supported.");

        RuleFor(x => x.Distance)
            .Must(double.IsFinite)
            .WithMessage("Distance must be a finite number.")
            .GreaterThanOrEqualTo(0)
            .WithMessage("Distance cannot be negative.");

        RuleFor(x => x.DurationSeconds)
            .GreaterThan(0)
            .WithMessage("Duration must be greater than zero.");

        RuleFor(x => x.Calories)
            .GreaterThanOrEqualTo(0)
            .When(x => x.Calories.HasValue)
            .WithMessage("Calories cannot be negative.");

        RuleFor(x => x.StartedAt)
            .NotEmpty();
    }
}