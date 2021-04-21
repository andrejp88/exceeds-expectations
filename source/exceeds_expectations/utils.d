module exceeds_expectations.utils;

import colorize;
import exceeds_expectations;
import std.algorithm;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.traits;


package string formatCode(string source, size_t focusLine, size_t radius)
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
        .map!convertTabsToSpaces
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

private string convertTabsToSpaces(string line)
{
    if (line.length == 0 || line[0] != '\t')
    {
        return line;
    }
    else
    {
        return "    " ~ convertTabsToSpaces(line[1..$]);
    }
}

@("convertTabsToSpaces — empty line")
unittest
{
    expect(convertTabsToSpaces("")).toEqual("");
}

@("convertTabsToSpaces — no indentation")
unittest
{
    expect(convertTabsToSpaces("Test\tHello World\t\t  ")).toEqual("Test\tHello World\t\t  ");
}

@("convertTabsToSpaces — tabs indentation")
unittest
{
    expect(convertTabsToSpaces("\t\t\tTest\tHello World\t\t  ")).toEqual("            Test\tHello World\t\t  ");
}



package string formatDifferences(string expected, string received)
{
    string expectedString = "Expected: " ~ expected.color(fg.green) ~ (expected.isMultiline ? "\n" : "");
    string receivedString = "Received: " ~ received.color(fg.light_red);
    return expectedString ~ "\n" ~ receivedString;
}

package string formatApproxDifferences(TReceived, TExpected, F : real)(
    const auto ref TReceived received,
    const auto ref TExpected expected,
    F maxRelDiff = CommonDefaultFor!(TReceived, TExpected),
    F maxAbsDiff = 0.0
)
{
    immutable real relDiff = fabs((received - expected) / expected);
    immutable real absDiff = fabs(received - expected);

    return formatDifferences(stringify(expected), stringify(received)) ~ "\n" ~

        "Relative Difference: " ~
        stringify(relDiff).color(fg.yellow) ~ getOrderOperator(relDiff, maxRelDiff) ~ stringify(maxRelDiff) ~
        " (maxRelDiff)\n" ~

        "Absolute Difference: " ~
        stringify(absDiff).color(fg.yellow) ~ getOrderOperator(absDiff, maxAbsDiff) ~ stringify(maxAbsDiff) ~
        " (maxAbsDiff)\n";
}

private string getOrderOperator(L, R)(L lhs, R rhs)
{
    return lhs > rhs ? " > " : lhs < rhs ? " < " : " = ";
}


package string stringify(T)(T t)
{
    string rawStringified;

    static if (is(T == class) && !__traits(isOverrideFunction, T.toString))
    {
        rawStringified = stringifyClassObject(t);
    }
    else static if (isFloatingPoint!T)
    {
        string asString = "%.14f".format(t);
        rawStringified = asString.canFind('.') ? asString.stripRight("0.") : asString;
    }
    else static if (isSomeString!T)
    {
        rawStringified = '"' ~ t ~ '"';
    }
    else
    {
        rawStringified = t.to!string;
    }

    if (rawStringified == "") rawStringified = t.to!string;

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

private string[] fieldTypeStrings(T)()
{
    string[] types;

    foreach (type; Fields!T)
    {
        types ~= type.stringof;
    }


    return types;
}

// Covers function pointers as well.
package string stringifyReference(T)(T t)
if (isPointer!T)
{
    return t.to!string;
}

package string stringifyReference(T)(T t)
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


/// Given an array of orderable elements,
///
/// Example:
///     Given `[]` return ""
///
/// Example:
///     Given `[1]` return "1"
///
/// Example:
///     Given `[3, 0]` return "0 and 3"
///
/// Example:
///     Given `[1, 0, 3]` returns "0, 1, and 3"
package string stringifyArray(N)(N[] numbers)
if (isOrderingComparable!N)
{
    if (numbers.length == 0) return "";

    auto strings = numbers.sort.map!(e => e.to!string);

    return (
        strings.length == 1 ? strings[0] :
        strings.length == 2 ? strings.join(" and ") :
        strings[0 .. $ - 1].join(", ") ~ ", and " ~ strings[$ - 1]
    );
}


/// This is defined in std.math but it's private.
package template CommonDefaultFor(T,U)
{
    import std.algorithm.comparison : min;

    alias baseT = FloatingPointBaseType!T;
    alias baseU = FloatingPointBaseType!U;

    enum CommonType!(baseT, baseU) CommonDefaultFor = 10.0L ^^ -((min(baseT.dig, baseU.dig) + 1) / 2 + 1);
}

/// ditto
private template FloatingPointBaseType(T)
{
    import std.range.primitives : ElementType;
    static if (isFloatingPoint!T)
    {
        alias FloatingPointBaseType = Unqual!T;
    }
    else static if (isFloatingPoint!(ElementType!(Unqual!T)))
    {
        alias FloatingPointBaseType = Unqual!(ElementType!(Unqual!T));
    }
    else
    {
        alias FloatingPointBaseType = real;
    }
}

package enum bool canCompareForEquality(L, R) = __traits(compiles, rvalueOf!L == rvalueOf!R);
