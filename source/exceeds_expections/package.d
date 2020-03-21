module exceeds_expections;

import colorize;
import std.algorithm.comparison;
import std.algorithm.iteration;
import std.algorithm.searching;
import std.conv;
import std.range;
import std.stdio;
import std.string;
import std.traits;


/**
 *  Represents an assertion failure in exceeds_expectations.
 */
public class EEException : Exception
{
    /// Constructs a new EEException
    private this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
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
public Expectation!(T, file) expect(T, string file = __FILE__)(const T subject, size_t line = __LINE__)
{
    return Expectation!(T, file)(subject, line);
}

/**
 *  Wraps any object and allows assertions to be run.
 */
public struct Expectation(T, string file = __FILE__)
{
    private const(T) subject;
    private size_t line;

    private enum string fileContents = import(file);

    private this(const(T) subject, size_t line)
    {
        this.subject = subject;
        this.line = line;
    }

    /// Throws an exception unless `subject == other`.
    public void toEqual(TOther)(const auto ref TOther other)
    if (isImplicitlyConvertible!(T, TOther))
    {
        if (subject != other)
        {
            string stringOfSubject = subject.to!string;
            string stringOfOther = other.to!string;

            static if (is(T == class) && !__traits(isOverrideFunction, T.toString))
            {
                stringOfSubject = stringifyClassObject(subject);
            }

            static if (is(TOther == class) && !__traits(isOverrideFunction, TOther.toString))
            {
                stringOfOther = stringifyClassObject(other);
            }

            bool areStringsMultiline = stringOfSubject.canFind('\n') || stringOfOther.canFind('\n');

            throw new EEException(
                "Arguments are not equal.\n" ~
                "Failing expectation at " ~ file ~ "(" ~ line.to!string ~ "): \n" ~
                "\n" ~ formatCode(fileContents, line, 2) ~ "\n" ~
                "Expected: " ~ (areStringsMultiline ? "\n" : "") ~
                stringOfSubject.color("green") ~ "\n" ~ (areStringsMultiline ? "\n" : "") ~
                "Received: " ~ (areStringsMultiline ? "\n" : "") ~
                stringOfOther.color("red") ~ "\n",
                file,
                line
            );
        }
    }
}

private string formatCode(const string source, size_t focusLine, size_t radius)
in (
    focusLine != 0,
    "focusLine must be at least 1"
)
in (
    focusLine < source.splitLines.length,
    "focusLine must not be larger than the last line in the source (" ~ focusLine.to!string ~ " > " ~ source.splitLines.length.to!string ~ ")"
)
in (
    source.splitLines.length > 0, "source may not be empty"
)
{
    const string[] sourceLines = source[$ - 1] == '\n' ? source.splitLines ~ "" : source.splitLines;
    immutable size_t sourceLength = sourceLines.length;
    immutable size_t focusLineIndex = focusLine - 1;

    immutable size_t firstLineIndex =
        focusLineIndex.to!int - radius.to!int < 0 ?
        0 :
        focusLineIndex - radius;

    immutable size_t lastLineIndex =
        focusLineIndex + radius >= sourceLength ?
        sourceLength - 1 :
        focusLineIndex + radius;

    return
        sourceLines[firstLineIndex .. lastLineIndex + 1]
        .zip(iota(firstLineIndex, lastLineIndex + 1))
        .map!((tup) {
            immutable string lineContents = (tup[1] + 1).to!string.padLeft(' ', 4).to!string ~ " | " ~ tup[0];
            return
                tup[1] == focusLineIndex ?
                lineContents.color(fg.yellow) :
                lineContents;
        })
        .join('\n') ~ "\n";
}

private string stringifyClassObject(T)(const T object)
if (is(T == class))
{
    import std.range : Appender;

    Appender!string output;

    output.put(T.stringof);
    output.put(" {\n");

    static foreach (tup; zip(fieldTypeStrings!T, [ FieldNameTuple!T ]))
    {
        output.put("    ");
        output.put(tup[0]);
        output.put(" ");
        output.put(tup[1]);
        output.put(" = ");
        output.put(__traits(getMember, object, tup[1]).to!string);
        output.put(";\n");
    }

    output.put("}");

    return output.data;
}

private enum string[] fieldTypeStrings(T) = fieldTypeStrings_!T;

private string[] fieldTypeStrings_(T)() {
    string[] types;

    foreach (type; Fields!T)
    {
        types ~= type.stringof;
    }


    return types;
}
