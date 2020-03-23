module exceeds_expections;

import colorize;
import std.algorithm.comparison;
import std.algorithm.iteration;
import std.algorithm.searching;
import std.conv;
import std.format;
import std.math;
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
public Expectation!(T, file) expect(T, string file = __FILE__)(const T actual, size_t line = __LINE__)
{
    return Expectation!(T, file)(actual, line);
}

/**
 *  Wraps any object and allows assertions to be run.
 */
public struct Expectation(TReceived, string file = __FILE__)
{
    private const(TReceived) received;

    private size_t line;
    private enum string fileContents = import(file);

    private this(const(TReceived) received, size_t line)
    {
        this.received = received;
        this.line = line;
    }

    /// Throws an [EEException] unless `received == expected`.
    public void toEqual(TExpected)(const auto ref TExpected expected)
    if (isImplicitlyConvertible!(TReceived, TExpected))
    {
        if (received != expected)
        {
            string stringOfReceived = stringify(received);
            string stringOfExpected = stringify(expected);

            immutable bool areStringsMultiline = stringOfReceived.canFind('\n') || stringOfExpected.canFind('\n');

            throw new EEException(
                "Arguments are not equal.\n" ~
                "Failing expectation at " ~ file ~ "(" ~ line.to!string ~ "): \n" ~
                "\n" ~ formatCode(fileContents, line, 2) ~ "\n" ~
                "Expected: " ~ (areStringsMultiline ? "\n" : "") ~
                stringOfExpected.color("green") ~ "\n" ~ (areStringsMultiline ? "\n" : "") ~
                "Received: " ~ (areStringsMultiline ? "\n" : "") ~
                stringOfReceived.color("red") ~ "\n",
                file,
                line
            );
        }
    }

    /// Throws an [EEException] unless `predicate(received)` returns true.
    public void toSatisfy(bool delegate(const(TReceived)) predicate)
    {
        if (!predicate(received))
        {
            string stringOfReceived = stringify(received);

            immutable bool areStringsMultiline = stringOfReceived.canFind('\n');

            throw new EEException(
                "Received value does not satisfy the predicate.\n" ~
                "Failing expectation at " ~ file ~ "(" ~ line.to!string ~ "): \n" ~
                "\n" ~ formatCode(fileContents, line, 2) ~ "\n" ~
                "Received: " ~ (areStringsMultiline ? "\n" : "") ~
                stringOfReceived.color("red") ~ "\n",
                file,
                line
            );
        }
    }

    /// Throws an [EEException] unless `predicate(received)` returns true for all predicates in `predicates`.
    public void toSatisfyAll(bool delegate(const(TReceived))[] predicates...)
    {
        if (predicates.length == 0)
        {
            throw new EEException(
                "Missing predicates at " ~ file ~ "(" ~ line.to!string ~ "): \n" ~
                "\n" ~ formatCode(fileContents, line, 2) ~ "\n",
                file, line
            );
        }

        if (predicates.length == 1)
        {
            toSatisfy(predicates[0]);
        }

        auto results = predicates.map!(p => p(received));
        immutable size_t numFailures = results.count!(e => !e);

        if (numFailures == 0) return;

        string stringOfReceived = stringify(received);

        string[] failingIndices =
            results
            .zip(iota(0, results.length))
            .filter!(tup => !tup[0])
            .map!(tup => tup[1].to!string)
            .array;

        immutable string failingIndicesString =
            numFailures == 1 ? failingIndices[0] :
            numFailures == 2 ? failingIndices.join(" and ") :
            failingIndices[0 .. $ - 1].join(", ") ~ ", and " ~ failingIndices[$ - 1];

        string blame =
            numFailures == predicates.length ? "Received value does not satisfy any predicates." :
            "Received value does not satisfy " ~
            (numFailures == 1 ? "predicate at index " : "predicates at indices ") ~
            failingIndicesString ~ " (first argument is index 0).";

        immutable bool areStringsMultiline = stringOfReceived.canFind('\n');

        throw new EEException(
            blame ~ "\n" ~
            "Failing expectation at " ~ file ~ "(" ~ line.to!string ~ "): \n" ~
            "\n" ~ formatCode(fileContents, line, 2) ~ "\n" ~
            "Received: " ~ (areStringsMultiline ? "\n" : "") ~
            stringOfReceived.color("red") ~ "\n",
            file, line
        );
    }

    /// Throws an [EEException] if `predicate(received)` returns false for all predicates in `predicates`.
    public void toSatisfyAny(bool delegate(const(TReceived))[] predicates...)
    {
        if (predicates.length == 0)
        {
            throw new EEException(
                "Missing predicates at " ~ file ~ "(" ~ line.to!string ~ "): \n" ~
                "\n" ~ formatCode(fileContents, line, 2) ~ "\n",
                file, line
            );
        }

        if (predicates.length == 1)
        {
            toSatisfy(predicates[0]);
        }

        foreach (predicate; predicates)
        {
            if (predicate(received)) return;
        }

        string stringOfReceived = stringify(received);
        immutable bool areStringsMultiline = stringOfReceived.canFind('\n');

        throw new EEException(
            "Received value does not satisfy any predicates.\n" ~
            "Failing expectation at " ~ file ~ "(" ~ line.to!string ~ "): \n" ~
            "\n" ~ formatCode(fileContents, line, 2) ~ "\n" ~
            "Received: " ~ (areStringsMultiline ? "\n" : "") ~
            stringOfReceived.color("red") ~ "\n",
            file, line
        );
    }

    /// Throws an [EEException] unless `received.approxEqual(expected, maxRelDiff, maxAbsDiff)`.
    public void toApproximatelyEqual(TExpected, F : real)(
        const auto ref TExpected expected,
        F maxRelDiff = 0.01,
        F maxAbsDiff = 1.0e-05
    )
    if (
        isImplicitlyConvertible!(TReceived, TExpected) &&
        __traits(compiles, received.approxEqual(expected, maxRelDiff, maxAbsDiff))
    )
    {
        if (!received.approxEqual(expected, maxRelDiff, maxAbsDiff))
        {
            string stringOfRelDiff = stringify(fabs((received - expected) / expected));
            string stringOfAbsDiff = stringify(fabs(received - expected));

            throw new EEException(
                "Arguments are not approximately equal.\n" ~
                "Failing expectation at " ~ file ~ "(" ~ line.to!string ~ "): \n" ~
                "\n" ~ formatCode(fileContents, line, 2) ~ "\n" ~
                "Expected: " ~ stringify(expected).color("green") ~ "\n" ~
                "Received: " ~ stringify(received).color("red") ~ "\n" ~
                "Relative Difference: " ~ stringOfRelDiff.color("yellow") ~
                " > " ~ stringify(maxRelDiff) ~ " (maxRelDiff)\n" ~
                "Absolute Difference: " ~ stringOfAbsDiff.color("yellow") ~
                " > " ~ stringify(maxAbsDiff) ~ " (maxAbsDiff)\n",
                file, line
            );
        }
    }

    /// Throws an [EEException] unless `received is expected`.
    public void toBe(TExpected)(const auto ref TExpected expected)
    {
        static if (!__traits(compiles, received is expected))
        {
            return false;
        }

        if (received !is expected)
        {
            string stringOfReceived;
            string stringOfExpected;

            static if (
                is(TReceived == struct) ||
                is(TReceived == union) ||
                is(TReceived == enum) ||
                (isBuiltinType!TReceived && !is(TReceived == void)) ||
                isStaticArray!TReceived
            )
            {
                stringOfReceived = stringify(received);
                stringOfExpected = stringify(expected);
            }
            else
            {
                static if (!isDelegate!TReceived)
                {
                    stringOfReceived = stringifyReference(received);
                }
                else
                {
                    stringOfReceived = "<a different delegate>";
                }

                static if (!isDelegate!TExpected)
                {
                    stringOfExpected = stringifyReference(expected);
                }
                else
                {
                    stringOfExpected = "<delegate>";
                }
            }

            throw new EEException(
                "Arguments are not equal.\n" ~
                "Failing expectation at " ~ file ~ "(" ~ line.to!string ~ "): \n" ~
                "\n" ~ formatCode(fileContents, line, 2) ~ "\n" ~
                "Expected: " ~ stringOfExpected.color("green") ~ "\n" ~
                "Received: " ~ stringOfReceived.color("red") ~ "\n",
                file, line
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
    immutable size_t firstFocusLineIndex = focusLine - 1;
    immutable size_t lastFocusLineIndex = sourceLines[firstFocusLineIndex..$].countUntil!(e => e.canFind(';')) + firstFocusLineIndex;

    immutable size_t firstLineIndex =
        firstFocusLineIndex.to!int - radius.to!int < 0 ?
        0 :
        firstFocusLineIndex - radius;

    immutable size_t lastLineIndex =
        lastFocusLineIndex + radius >= sourceLength ?
        sourceLength - 1 :
        lastFocusLineIndex + radius;

    return
        sourceLines[firstLineIndex .. lastLineIndex + 1]
        .zip(iota(firstLineIndex, lastLineIndex + 1))
        .map!((tup) {
            immutable string lineContents = (tup[1] + 1).to!string.padLeft(' ', 4).to!string ~ " | " ~ tup[0];
            return
                tup[1] >= firstFocusLineIndex && tup[1] <= lastFocusLineIndex ?
                lineContents.color(fg.yellow) :
                lineContents;
        })
        .join('\n') ~ "\n";
}

private string stringify(T)(T t)
{
    static if (is(T == class) && !__traits(isOverrideFunction, T.toString))
    {
        return stringifyClassObject(t);
    }
    else static if (isFloatingPoint!T)
    {
        string asString = "%.14f".format(t);
        return asString.canFind('.') ? asString.stripRight("0.") : asString;
    }
    else
    {
        return t.to!string;
    }
}

private string stringifyClassObject(T)(const T object)
if (is(T == class))
{
    import std.range : Appender;

    Appender!string output;

    output.put(T.stringof);
    output.put(" {\n");

    static foreach (tup; zip(fieldTypeStrings!T, cast(string[])[ FieldNameTuple!T ]))
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

// Covers function pointers as well.
private string stringifyReference(T)(T t)
if (isPointer!T)
{
    return t.to!string;
}

private string stringifyReference(T)(T t)
if (
    is(T == class) ||
    is(T == interface) ||
    isDynamicArray!T ||
    isAssociativeArray!T
)
{
    return stringifyReference(cast(void*)t);
}

// private string stringifyReference(T)(ref T t)
// if (
//     is(T == struct) ||
//     is(T == union) ||
//     is(T == enum) ||
//     (isBuiltinType!T && !is(T == void)) ||
//     isStaticArray!T
// )
// {
//     return (&t).to!string;
// }
