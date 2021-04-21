module exceeds_expectations.exceptions;

import exceeds_expectations.utils;
import std.array;
import std.exception;
import std.file : readText;


/**
 *  Represents an assertion failure in exceeds_expectations.
 */
public class FailingExpectationException : Exception
{
    /// Constructs a new FailingExpectationException
    package this(const string message, const string filePath = __FILE__, size_t line = __LINE__, Throwable next = null)
    @safe pure nothrow
    {
        super(message, filePath, line, next);
    }

    /// ditto
    package this(
        const string description,
        const string location,
        const string differences,
        const string filePath = __FILE__,
        size_t line = __LINE__,
        Throwable next = null
    )
    {
        Appender!string message;

        message.put(location); message.put('\n');

        if (description != "")
        {
            message.put(description); message.put('\n');
        }

        message.put('\n');
        message.put(formatCode(readText(filePath), line, 2));

        if (differences != "")
        {
            message.put('\n');
            message.put(differences);
            message.put('\n');
        }

        this(message.data, filePath, line, next);
    }
}
