namespace PaceUp.Application.Exceptions;

public class EmailDeliveryException : Exception
{
    public EmailDeliveryException(string message, Exception? innerException = null)
        : base(message, innerException)
    {
    }
}
