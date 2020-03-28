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
    private this(const string message, const string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    @safe pure nothrow
    {
        super(message, file, line, next);
    }

    /// ditto
    private this(
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
    private immutable string expectationCodeLocation;
    private immutable string expectationCodeExcerpt;

    private this(const(TReceived) received, size_t line)
    {
        this.received = received;
        this.line = line;
        this.expectationCodeLocation = "Failing expectation at " ~ file ~ "(" ~ line.to!string ~ ")";
        this.expectationCodeExcerpt = formatCode(fileContents, line, 2);
    }

    private void throwEEException(string differences, string description = "")
    {
        throw new EEException(
            description,
            expectationCodeLocation,
            expectationCodeExcerpt,
            differences,
            file, line
        );
    }

    /// Throws an [EEException] unless `received == expected`.
    public void toEqual(TExpected)(const auto ref TExpected expected)
    if (isImplicitlyConvertible!(TReceived, TExpected))
    {
        if (received != expected)
        {
            throwEEException(
                formatDifferences(stringify(expected), stringify(received))
            );
        }
    }

    /// Throws an [EEException] unless `predicate(received)` returns true.
    public void toSatisfy(bool delegate(const(TReceived)) predicate)
    {
        if (!predicate(received))
        {
            throwEEException(
                "Received: " ~ stringify(received).color(fg.light_red)
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

        immutable string description =
            numFailures == predicates.length ? "Received value does not satisfy any predicates." :
            "Received value does not satisfy " ~
            (numFailures == 1 ? "predicate at index " : "predicates at indices ") ~
            failingIndicesString ~ " (first argument is index 0).";

        throwEEException(
            "Received: " ~ stringify(received).color(fg.light_red),
            description
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

        throwEEException(
            "Received: " ~ stringOfReceived.color(fg.light_red)
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

            throwEEException(
                formatDifferences(stringify(expected), stringify(received)) ~ "\n" ~

                "Relative Difference: " ~ stringOfRelDiff.color(fg.yellow) ~
                " > " ~ stringify(maxRelDiff) ~ " (maxRelDiff)\n" ~

                "Absolute Difference: " ~ stringOfAbsDiff.color(fg.yellow) ~
                " > " ~ stringify(maxAbsDiff) ~ " (maxAbsDiff)\n"
            );
        }
    }

    alias toBeCloseTo = toApproximatelyEqual;

    /// Throws an [EEException] unless `received is expected`.
    public void toBe(TExpected)(const auto ref TExpected expected)
    {
        static if (
            is(TReceived == struct) ||
            is(TReceived == union) ||
            is(TReceived == enum) ||
            (isBuiltinType!TReceived && !is(TReceived == void)) ||
            isStaticArray!TReceived
        )
        {
            toEqual(expected);
            return;
        }
        else static if (!__traits(compiles, received is expected))
        {
            throwEEException(
                formatDifferences(TExpected.stringof, TReceived.stringof),
                "Arguments do not reference the same type."
            );
        }
        else
        {
            if (received !is expected)
            {
                throwEEException(
                    "",
                    "Arguments do not reference the same object (received !is expected)."
                );
            }
        }
    }
}

private string formatCode(string source, size_t focusLine, size_t radius)
in (
    focusLine != 0,
    "focusLine must be at least 1"
)
in (
    focusLine < source.splitLines.length,
    "focusLine must not be larger than the last line in the source (" ~
    focusLine.to!string ~ " > " ~ source.splitLines.length.to!string ~ ")"
)
in (
    source.splitLines.length > 0, "source may not be empty"
)
{
    const string[] sourceLines = source[$ - 1] == '\n' ? source.splitLines ~ "" : source.splitLines;
    immutable size_t sourceLength = sourceLines.length;
    immutable size_t firstFocusLineIndex = focusLine - 1;
    immutable size_t lastFocusLineIndex =
        sourceLines[firstFocusLineIndex..$].countUntil!(e => e.canFind(';')) + firstFocusLineIndex;

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

private string formatDifferences(string expected, string received)
{
    return (
        "Expected: " ~ expected.color(fg.green) ~ (expected.isMultiline ? "\n\n" : "\n") ~
        "Received: " ~ received.color(fg.light_red)
    );
}

private string stringify(T)(T t)
{
    static if (is(T == class) && !__traits(isOverrideFunction, T.toString))
    {
        immutable string rawStringified = stringifyClassObject(t);
    }
    else static if (isFloatingPoint!T)
    {
        string asString = "%.14f".format(t);
        immutable string rawStringified = asString.canFind('.') ? asString.stripRight("0.") : asString;
    }
    else
    {
        immutable string rawStringified = t.to!string;
    }

    return (
        rawStringified.canFind('\n') ? "\n" : ""
    ) ~ (rawStringified);
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

private string[] fieldTypeStrings(T)() {
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

private bool isMultiline(string s)
{
    return s.canFind('\n');
}
