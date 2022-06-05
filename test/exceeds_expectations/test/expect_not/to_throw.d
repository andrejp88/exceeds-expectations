module exceeds_expectations.test.expect_not.to_throw;

import exceeds_expectations;
import exceeds_expectations.test;


@("succeed when it throws the wrong thing")
unittest
{
    class CustomException : Exception
    {
        this(string message, string file = __FILE__, int line = __LINE__, Throwable nextInChain = null)
        {
            super(message, file, line, nextInChain);
        }
    }

    expect({ throw new Exception("test"); }).not.toThrow!CustomException;
}

@("succeed when it doesn't throw anything")
unittest
{
    expect({ return; }).not.toThrow!Exception;
}

@("fail when it throws the exact thing")
unittest
{
    shouldFail(
        expect({ throw new Exception("Test"); }).not.toThrow!Exception
    );
}

@("fail when it throws a sub-type")
unittest
{
    class CustomException : Exception
    {
        this(string message, string file = __FILE__, int line = __LINE__, Throwable nextInChain = null)
        {
            super(message, file, line, nextInChain);
        }
    }

    shouldFail(
        expect({ throw new CustomException("Test"); }).not.toThrow
    );
}

@("succeed if it throws the right type but the message does not match")
unittest
{
    class UnexpectedValueException : Exception
    {
        this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null)
        pure nothrow @safe
        {
            super("Unexpected value: " ~ msg, file, line, nextInChain);
        }
    }

    expect({
        throw new UnexpectedValueException("spanish inquisition");
    }).not.toThrow!UnexpectedValueException("something else");
}

@("succeed if the message matches but the type is wrong")
unittest
{
    class UnexpectedValueException : Exception
    {
        this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null)
        pure nothrow @safe
        {
            super("Unexpected value: " ~ msg, file, line, nextInChain);
        }
    }

    expect({
        throw new UnexpectedValueException("spanish inquisition");
    }).not.toThrow!Error("spanish inquisition");
}

@("fail if the type and message both match")
unittest
{
    class UnexpectedValueException : Exception
    {
        this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable nextInChain = null)
        pure nothrow @safe
        {
            super("Unexpected value: " ~ msg, file, line, nextInChain);
        }
    }

    shouldFail(
        expect({
            throw new UnexpectedValueException("spanish inquisition");
        }).toThrow!UnexpectedValueException("spanish inquisition")
    );
}
