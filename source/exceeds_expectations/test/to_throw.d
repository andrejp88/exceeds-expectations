module exceeds_expectations.test.to_throw;

import exceeds_expectations.expectation;
import exceeds_expectations.test;


@("Succeed if expecting a super-type")
unittest
{
    expect({ throw new Exception("fail"); }).toThrow!Throwable;
}

@("Fail if expecting an unrelated Exception")
unittest
{
    class SpecificException : Exception
    {
        this(string message, string file = __FILE__, int line = __LINE__, Throwable nextInChain = null)
        {
            super(message, file, line, nextInChain);
        }
    }

    class OtherException : Exception
    {
        this(string message, string file = __FILE__, int line = __LINE__, Throwable nextInChain = null)
        {
            super(message, file, line, nextInChain);
        }
    }

    shouldFail(
        expect({ throw new SpecificException("fail"); }).toThrow!OtherException
    );
}

@("Fail if expecting a sub-type")
unittest
{
    class SpecificException : Exception
    {
        this(string message, string file = __FILE__, int line = __LINE__, Throwable nextInChain = null)
        {
            super(message, file, line, nextInChain);
        }
    }

    shouldFail(
        expect({ throw new Exception("fail"); }).toThrow!SpecificException
    );
}

@("Fail if nothing is thrown")
unittest
{
    shouldFail(
        expect({ return; }).toThrow()
    );
}
