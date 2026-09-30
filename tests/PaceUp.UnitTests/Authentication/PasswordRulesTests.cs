using PaceUp.Application.Features.Authentication;

namespace PaceUp.UnitTests.Authentication;

public class PasswordRulesTests
{
    [Theory]
    [InlineData("Password1!")]
    [InlineData("PaceUp2026!")]
    [InlineData("StrongPassword9#")]
    public void IsValid_ShouldReturnTrue_ForValidPasswords(
        string password)
    {
        var result = PasswordRules.IsValid(password);

        Assert.True(result);
    }

    [Theory]
    [InlineData("")]
    [InlineData("short1!")]
    [InlineData("password1!")]
    [InlineData("PASSWORD1!")]
    [InlineData("Password!")]
    [InlineData("Password1")]
    public void IsValid_ShouldReturnFalse_ForInvalidPasswords(
        string password)
    {
        var result = PasswordRules.IsValid(password);

        Assert.False(result);
    }

    [Fact]
    public void IsValid_ShouldAcceptPassword_WithUnicodeLetters()
    {
        var result =
            PasswordRules.IsValid("PäceUp2026!");

        Assert.True(result);
    }
}