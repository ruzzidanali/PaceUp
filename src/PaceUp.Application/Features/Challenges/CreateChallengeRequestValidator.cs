using FluentValidation;
using PaceUp.Application.DTOs.Challenges;
using PaceUp.Domain.Constants;

namespace PaceUp.Application.Features.Challenges;

public class CreateChallengeRequestValidator
    : AbstractValidator<CreateChallengeRequest>
{
    public CreateChallengeRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .MaximumLength(150)
            .WithMessage(
                "Challenge name is required and must not exceed 150 characters.");

        RuleFor(x => x.Description)
            .MaximumLength(1000)
            .When(x => x.Description is not null)
            .WithMessage(
                "Challenge description must not exceed 1000 characters.");

        RuleFor(x => x.Type)
            .NotEmpty()
            .Must(ChallengeTypes.IsValid)
            .WithMessage(
                "Challenge type is not supported.");

        RuleFor(x => x.TargetValue)
            .GreaterThan(0)
            .WithMessage(
                "Challenge target must be greater than zero.");

        RuleFor(x => x.EndDate)
            .GreaterThanOrEqualTo(x => x.StartDate)
            .WithMessage(
                "Challenge end date must be greater than or equal to the start date.");
    }
}