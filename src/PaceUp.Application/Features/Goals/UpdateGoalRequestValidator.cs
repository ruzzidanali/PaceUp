using FluentValidation;
using PaceUp.Application.DTOs.Goals;
using PaceUp.Domain.Constants;

namespace PaceUp.Application.Features.Goals;

public class UpdateGoalRequestValidator
    : AbstractValidator<UpdateGoalRequest>
{
    public UpdateGoalRequestValidator()
    {
        RuleFor(x => x.Type)
            .NotEmpty()
            .Must(GoalTypes.IsValid)
            .WithMessage("Goal type is not supported.");

        RuleFor(x => x.Target)
            .GreaterThan(0)
            .WithMessage("Goal target must be greater than zero.");

        RuleFor(x => x.EndDate)
            .GreaterThanOrEqualTo(x => x.StartDate)
            .WithMessage(
                "Goal end date must be greater than or equal to the start date.");
    }
}