module exceeds_expections;

import std.stdio;
import std.conv;


/**
 *  Represents an assertion failure in exceeds_expectations.
 */
public class EEException : Exception
{
    /// Constructs a new EEException.
    this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    @safe pure nothrow
    {
        super(message, file, line, next);
    }


}

/**
 *	Initiates the expectation chain.
 *
 *  TODO: Try to make this auto-ref
 */
public Expectation!T expect(T)(const T subject, string file = __FILE__, size_t line = __LINE__)
{
    return Expectation!T(subject, file, line);
}

/**
 *  Wraps any object and allows assertions to be run.
 */
public struct Expectation(T)
{
    private T subject;
    private string file;
    private size_t line;

    private this(const T subject, string file, size_t line)
    {
        this.subject = subject;
        this.file = file;
        this.line = line;
    }

    /// Checks that two objects are equal according to '=='.
    public void toEqual(TOther)(const auto ref TOther other)
    {
        if (subject != other)
        {
            throw new EEException(
                `Expected ` ~ T.stringof ~ ` ` ~ subject.to!string ~
                ` but received ` ~ TOther.stringof ~ ` ` ~ other.to!string,
                file,
                line
            );
        }
    }
}
