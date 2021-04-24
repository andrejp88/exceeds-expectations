module exceeds_expectations.utils;

import colorize;
import exceeds_expectations;
import exceeds_expectations.pretty_print;
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
                truncate(lineContents, 120);
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

private string truncate(string line, int length)
in(length >= 0, "Cannot truncate line to length " ~ length.to!string)
{
    if (line.length > length)
    {
        return line[0 .. length - 4] ~ " ...".color(fg.light_black);
    }

    return line;
}

@("Truncate empty line")
unittest
{
    expect(truncate("", 80)).toEqual("");
}

@("Truncate non-empty line to a given length")
unittest
{
    expect(truncate("abcdefghijklmnopqrstuvwxyz", 10)).toEqual("abcdef" ~ " ...".color(fg.light_black));
}

@("Truncate — edge cases")
unittest
{
    expect(truncate("abcdefghij", 10)).toEqual("abcdefghij");
    expect(truncate("abcdefghijk", 10)).toEqual("abcdef" ~ " ...".color(fg.light_black));
}


package string formatDifferences(string expected, string received, bool not)
{
    string lineLabel1 = not ? "Forbidden: " : "Expected: ";
    string lineLabel2 = not ? "Received:  " : "Received: ";
    string expectedString = lineLabel1.color(fg.green) ~ expected ~ (expected.isMultiline ? "\n" : "");
    string receivedString = lineLabel2.color(fg.light_red) ~ received;
    return expectedString ~ "\n" ~ receivedString;
}


package string formatApproxDifferences(TReceived, TExpected, F : real)(
    const auto ref TExpected expected,
    const auto ref TReceived received,
    F maxRelDiff = CommonDefaultFor!(TReceived, TExpected),
    F maxAbsDiff = 0.0
)
{
    immutable real relDiff = fabs((received - expected) / expected);
    immutable real absDiff = fabs(received - expected);

    return
        "Relative Difference: ".color(fg.yellow) ~
        prettyPrint(relDiff) ~ getOrderOperator(relDiff, maxRelDiff) ~ prettyPrint(maxRelDiff) ~
        " (maxRelDiff)\n" ~

        "Absolute Difference: ".color(fg.yellow) ~
        prettyPrint(absDiff) ~ getOrderOperator(absDiff, maxAbsDiff) ~ prettyPrint(maxAbsDiff) ~
        " (maxAbsDiff)\n";
}

private string indentAllButFirst(string text, int numSpaces)
{
    return text
        .splitLines()
        .enumerate()
        .map!(
            idxValuePair => (
                idxValuePair[0] == 0 ?
                idxValuePair[1] :
                ' '.repeat(numSpaces).array.to!string ~ idxValuePair[1]
            )
        )
        .join("\n");
}

package string formatTypeDifferences(TypeInfo expected, TypeInfo received, bool not)
{
    if (TypeInfo_Class tic = cast(TypeInfo_Class) received)
    {
        return formatDifferences(
            prettyPrint(expected),
            prettyPrintInheritanceTree(received).indentAllButFirst(not ? 11 : 10),
            not
        );
    }

    return formatDifferences(
        prettyPrint(expected),
        prettyPrint(received),
        not
    );
}

private string getOrderOperator(L, R)(L lhs, R rhs)
{
    return lhs > rhs ? " > " : lhs < rhs ? " < " : " = ";
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
package string humanReadableNumbers(N)(N[] numbers)
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
