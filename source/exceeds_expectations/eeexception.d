module exceeds_expectations.eeexception;

import std.array;
import std.exception;


/**
 *  Represents an assertion failure in exceeds_expectations.
 */
public class EEException : Exception
{
    /// Constructs a new EEException
    package this(const string message, const string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    @safe pure nothrow
    {
        super(message, file, line, next);
    }

    /// ditto
    package this(
        const string description,
        const string location,
        const string codeExcerpt,
        const string differences,
        const string file = __FILE__,
        size_t line = __LINE__,
        Throwable next = null
    )
    @safe pure nothrow
    {
        Appender!string message;

        message.put(location); message.put('\n');

        if (description != "")
        {
            message.put(description); message.put('\n');
        }

        message.put('\n');
        message.put(codeExcerpt);

        if (differences != "")
        {
            message.put('\n');
            message.put(differences);
            message.put('\n');
        }

        this(message.data, file, line, next);
    }
}
