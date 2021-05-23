module exceeds_expectations.test.expect.to_throw;

import exceeds_expectations;
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

@("Accept structs with an opCall, as long as the opCall is const")
unittest
{
    struct Callable
    {
        void opCall() const
        {
            throw new Exception("test");
        }
    }

    Callable c;

    expect(c).toThrow!Exception;
}


@("Fail to compile if received is not callable")
unittest
{
    static assert(!__traits(compiles, expect(2).toThrow!Exception));
    static assert(!__traits(compiles, expect("hello world").toThrow!Exception));

    struct NotCallable {}
    NotCallable nc;
    static assert(!__traits(compiles, expect(nc).toThrow!Exception));
}
