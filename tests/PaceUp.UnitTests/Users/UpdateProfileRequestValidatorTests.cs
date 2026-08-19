using PaceUp.Application.DTOs.Users;
using PaceUp.Application.Features.Users;

namespace PaceUp.UnitTests.Users;

public class UpdateProfileRequestValidatorTests
{
    private readonly UpdateProfileRequestValidator _validator = new();

    [Fact]
    public void Validate_WithValidRequest_ShouldPass()
    {
        var request =
            new UpdateProfileRequest(
                "Ruzzidan",
                "Full Stack Developer");

        var result =
            _validator.Validate(request);

        Assert.True(result.IsValid);
    }

    [Fact]
    public void Validate_WithEmptyDisplayName_ShouldFail()
    {
        var request =
            new UpdateProfileRequest(
                "",
                "My bio");

        var result =
            _validator.Validate(request);

        Assert.False(result.IsValid);

        Assert.Contains(
            result.Errors,
            x => x.ErrorMessage ==
                "Display name is required.");
    }

    [Fact]
    public void Validate_WithDisplayNameOver100Characters_ShouldFail()
    {
        var request =
            new UpdateProfileRequest(
                new string('A', 101),
                "My bio");

        var result =
            _validator.Validate(request);

        Assert.False(result.IsValid);

        Assert.Contains(
            result.Errors,
            x => x.ErrorMessage ==
                "Display name cannot exceed 100 characters.");
    }

    [Fact]
    public void Validate_WithBioOver500Characters_ShouldFail()
    {
        var request =
            new UpdateProfileRequest(
                "Ruzzidan",
                new string('A', 501));

        var result =
            _validator.Validate(request);

        Assert.False(result.IsValid);

        Assert.Contains(
            result.Errors,
            x => x.ErrorMessage ==
                "Bio cannot exceed 500 characters.");
    }

    [Fact]
    public void Validate_WithNullBio_ShouldPass()
    {
        var request =
            new UpdateProfileRequest(
                "Ruzzidan",
                null);

        var result =
            _validator.Validate(request);

        Assert.True(result.IsValid);
    }
}