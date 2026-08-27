using PaceUp.Application.DTOs.Challenges;
using PaceUp.Application.Features.Challenges;

namespace PaceUp.UnitTests.Challenges;

public class ChallengeRequestValidatorTests
{
    [Fact]
    public void Create_ShouldAcceptValidRequest()
    {
        var validator =
            new CreateChallengeRequestValidator();

        var request =
            new CreateChallengeRequest(
                "Run 50 KM",
                "Complete 50 KM.",
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            validator.Validate(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public void Create_WithEmptyName_ShouldBeInvalid()
    {
        var validator =
            new CreateChallengeRequestValidator();

        var request =
            new CreateChallengeRequest(
                "",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            validator.Validate(request);

        Assert.False(result.IsValid);
        Assert.Contains(
            result.Errors,
            x => x.PropertyName == nameof(request.Name));
    }

    [Fact]
    public void Create_WithNameLongerThan150Characters_ShouldBeInvalid()
    {
        var validator =
            new CreateChallengeRequestValidator();

        var request =
            new CreateChallengeRequest(
                new string('A', 151),
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            validator.Validate(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public void Create_WithDescriptionLongerThan1000Characters_ShouldBeInvalid()
    {
        var validator =
            new CreateChallengeRequestValidator();

        var request =
            new CreateChallengeRequest(
                "Run Challenge",
                new string('A', 1001),
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            validator.Validate(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public void Create_WithInvalidType_ShouldBeInvalid()
    {
        var validator =
            new CreateChallengeRequestValidator();

        var request =
            new CreateChallengeRequest(
                "Run Challenge",
                null,
                "Invalid",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            validator.Validate(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public void Create_WithZeroTarget_ShouldBeInvalid()
    {
        var validator =
            new CreateChallengeRequestValidator();

        var request =
            new CreateChallengeRequest(
                "Run Challenge",
                null,
                "Distance",
                0,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            validator.Validate(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public void Create_WithNegativeTarget_ShouldBeInvalid()
    {
        var validator =
            new CreateChallengeRequestValidator();

        var request =
            new CreateChallengeRequest(
                "Run Challenge",
                null,
                "Distance",
                -10,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            validator.Validate(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public void Create_WithEndDateBeforeStartDate_ShouldBeInvalid()
    {
        var validator =
            new CreateChallengeRequestValidator();

        var startDate =
            DateTime.UtcNow.Date;

        var request =
            new CreateChallengeRequest(
                "Run Challenge",
                null,
                "Distance",
                50,
                startDate,
                startDate.AddDays(-1));

        var result =
            validator.Validate(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public void Update_ShouldAcceptValidRequest()
    {
        var validator =
            new UpdateChallengeRequestValidator();

        var request =
            new UpdateChallengeRequest(
                "Updated Challenge",
                "Updated description",
                "Duration",
                3600,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            validator.Validate(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public void Update_WithEmptyName_ShouldBeInvalid()
    {
        var validator =
            new UpdateChallengeRequestValidator();

        var request =
            new UpdateChallengeRequest(
                "",
                null,
                "Distance",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            validator.Validate(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public void Update_WithInvalidType_ShouldBeInvalid()
    {
        var validator =
            new UpdateChallengeRequestValidator();

        var request =
            new UpdateChallengeRequest(
                "Updated Challenge",
                null,
                "Invalid",
                50,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            validator.Validate(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public void Update_WithZeroTarget_ShouldBeInvalid()
    {
        var validator =
            new UpdateChallengeRequestValidator();

        var request =
            new UpdateChallengeRequest(
                "Updated Challenge",
                null,
                "Distance",
                0,
                DateTime.UtcNow.Date,
                DateTime.UtcNow.Date.AddDays(6));

        var result =
            validator.Validate(request);

        Assert.False(result.IsValid);
    }

    [Fact]
    public void Update_WithEndDateBeforeStartDate_ShouldBeInvalid()
    {
        var validator =
            new UpdateChallengeRequestValidator();

        var startDate =
            DateTime.UtcNow.Date;

        var request =
            new UpdateChallengeRequest(
                "Updated Challenge",
                null,
                "Distance",
                50,
                startDate,
                startDate.AddDays(-1));

        var result =
            validator.Validate(request);

        Assert.False(result.IsValid);
    }
}