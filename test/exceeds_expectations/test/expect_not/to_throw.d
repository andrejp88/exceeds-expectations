module exceeds_expectations.test.expect_not.to_throw;

import exceeds_expectations;
import exceeds_expectations.test;


@("toThrow, since it throws the wrong thing")
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

@("toThrow, since it doesn't throw anything")
unittest
{
    expect({ return; }).not.toThrow!Exception;
}

@("toThrow, but throws the exact thing")
unittest
{
    shouldFail(
        expect({ throw new Exception("Test"); }).not.toThrow!Exception
    );
}

@("toThrow, but throws a sub-type")
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
