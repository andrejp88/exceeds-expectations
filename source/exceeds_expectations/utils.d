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


/// Returns a string showing the expected and received values. Ends
/// with a line separator.
package string formatDifferences(string expected, string received, bool not)
{
    immutable string lineLabel1 = (not ? "Forbidden: " : "Expected: ").color(fg.green);
    immutable string lineLabel2 = (not ? "Received:  " : "Received: ").color(fg.light_red);
    return (
        lineLabel1 ~ expected ~ "\n" ~
        lineLabel2 ~ received ~ "\n"
    );
}

package string formatFailureMessage(string[] args...)
out(result; result.endsWith("\n") || result == "")
{
    if (args.length == 0)
    {
        return "";
    }

    Appender!string result;

    size_t longestLabelLength = size_t.max;

    if (args.length >= 2)
    {
        longestLabelLength =
            args
            .chunks(2)
            .filter!(e => e.length == 2)
            .filter!(e => !(e[1].canFind('\n')))
            .map!(e => e[0])
            .maxElement!(e => e.length)("")
            .length;
    }

    foreach (size_t i, string[] chunk; args.chunks(2).array)
    {
        if (chunk.length == 2)
        {
            fg labelColor = (
                i == 0 ?
                fg.green : (
                    i == 1 ?
                    fg.red :
                    fg.yellow
                )
            );

            result.put((chunk[0] ~ ":").color(labelColor));

            immutable bool isValueMultiline = chunk[1].canFind('\n');

            if (isValueMultiline)
            {
                result.put('\n');
            }
            else
            {
                assert(longestLabelLength != size_t.max, "Ended up with very long longestLabelLength");
                assert(longestLabelLength >= chunk[0].length, "Longest label is not the longest for some reason");
                size_t labelPadding = longestLabelLength - chunk[0].length;
                result.put(repeat(' ', labelPadding + 1));
            }

            result.put(chunk[1]);

            if (isValueMultiline) result.put('\n');
        }
        else
        {
            result.put(chunk[0]);
        }

        result.put('\n');
    }

    return result.data;
}

@("formatFailureMessage empty")
unittest
{
    expect(formatFailureMessage()).toEqual("");
}

@("formatFailureMessage simple message")
unittest
{
    expect(formatFailureMessage("I didn't expect a kind of Spanish Inquisition"))
        .toEqual("I didn't expect a kind of Spanish Inquisition\n");
}

@("formatFailureMessage one labeled row")
unittest
{
    expect(formatFailureMessage("Expected", "Not The Spanish Inquisition")).toEqual(
        "Expected:".color(fg.green) ~ " Not The Spanish Inquisition\n"
    );
}

@("formatFailureMessage one labeled row and one unlabeled row")
unittest
{
    expect(formatFailureMessage(
        "Expected", "Not The Spanish Inquisition",
        "Our chief weapon is surprise"
    )).toEqual(
        "Expected:".color(fg.green) ~ " Not The Spanish Inquisition\n" ~
        "Our chief weapon is surprise\n"
    );
}

@("formatFailureMessage two labeled rows with uneven labels")
unittest
{
    expect(formatFailureMessage(
        "Forbidden", "The Spanish Inquisition",
        "Received", "The Spanish Inquisition"
    )).toEqual(
        "Forbidden:".color(fg.green) ~ " The Spanish Inquisition\n" ~
        "Received:".color(fg.red) ~ "  The Spanish Inquisition\n"
    );
}

@("formatFailureMessage six labelled rows")
unittest
{
    expect(formatFailureMessage(
        "Forbidden", "The Spanish Inquisition",
        "Received", "The Spanish Inquisition",
        "Chief Weapon 1", "Surprise",
        "Chief Weapon 2", "Fear",
        "Chief Weapon 3", "Ruthless efficiency",
        "Chief Weapon 4", "An almost fanatical devotion to the Pope",
    )).toEqual(
        "Forbidden:".color(fg.green ) ~ "      The Spanish Inquisition\n" ~
        "Received:".color(fg.red   ) ~ "       The Spanish Inquisition\n" ~
        "Chief Weapon 1:".color(fg.yellow) ~ " Surprise\n" ~
        "Chief Weapon 2:".color(fg.yellow) ~ " Fear\n" ~
        "Chief Weapon 3:".color(fg.yellow) ~ " Ruthless efficiency\n" ~
        "Chief Weapon 4:".color(fg.yellow) ~ " An almost fanatical devotion to the Pope\n"
    );
}

@("formatFailureMessage six labelled rows and an unlabelled row")
unittest
{
    expect(formatFailureMessage(
        "Forbidden", "The Spanish Inquisition",
        "Received", "The Spanish Inquisition",
        "Chief Weapon 1", "Surprise",
        "Chief Weapon 2", "Fear",
        "Chief Weapon 3", "Ruthless efficiency",
        "Chief Weapon 4", "An almost fanatical devotion to the Pope",
        "Amongst our weapons... Amongst our weaponry... are such elements as fear, surprise... I'll come in again."
    )).toEqual(
        "Forbidden:".color(fg.green ) ~ "      The Spanish Inquisition\n" ~
        "Received:".color(fg.red   ) ~ "       The Spanish Inquisition\n" ~
        "Chief Weapon 1:".color(fg.yellow) ~ " Surprise\n" ~
        "Chief Weapon 2:".color(fg.yellow) ~ " Fear\n" ~
        "Chief Weapon 3:".color(fg.yellow) ~ " Ruthless efficiency\n" ~
        "Chief Weapon 4:".color(fg.yellow) ~ " An almost fanatical devotion to the Pope\n" ~
        "Amongst our weapons... Amongst our weaponry... are such elements as fear, surprise... I'll come in again.\n"
    );
}

@("formatFailureMessage with all multi-line values and an unlabelled line")
unittest
{
    expect(formatFailureMessage(
        "Forbidden", "The\nSpanish\nInquisition",
        "Received", "The\nSpanish\nInquisition",
        "Chief Weapons", "Surprise\nFear\nRuthless efficiency\nAn almost fanatical devotion to the Pope",
        "Amongst our weapons... Amongst our weaponry... are such elements as fear, surprise... I'll come in again."
    )).toEqual(
        "Forbidden:".color(fg.green ) ~ "\nThe\nSpanish\nInquisition\n\n" ~
        "Received:".color(fg.red   ) ~ "\nThe\nSpanish\nInquisition\n\n" ~
        "Chief Weapons:".color(fg.yellow) ~ "\nSurprise\nFear\nRuthless efficiency\nAn almost fanatical devotion to the Pope\n\n" ~
        "Amongst our weapons... Amongst our weaponry... are such elements as fear, surprise... I'll come in again.\n"
    );
}

@("formatFailureMessage with some multi-line values, some single-line values, and an unlabelled line")
unittest
{
    expect(formatFailureMessage(
        "Forbidden", "The Spanish Inquisition",
        "Received", "The Spanish Inquisition",
        "Chief Weapons", "Surprise\nFear\nRuthless efficiency\nAn almost fanatical devotion to the Pope",
        "Filler single-line", "This line has the longest label which all other single-line labels should obey.",
        "Filler multiple-line", "This is the longest label, but since it's value\nhas multiple lines, it's not taken into account.",
        "Amongst our weapons... Amongst our weaponry... are such elements as fear, surprise... I'll come in again."
    )).toEqual(
        "Forbidden:".color(fg.green ) ~ "          The Spanish Inquisition\n" ~
        "Received:".color(fg.red   ) ~ "           The Spanish Inquisition\n" ~
        "Chief Weapons:".color(fg.yellow) ~ "\nSurprise\nFear\nRuthless efficiency\nAn almost fanatical devotion to the Pope\n\n" ~
        "Filler single-line:".color(fg.yellow) ~ " This line has the longest label which all other single-line labels should obey.\n" ~
        "Filler multiple-line:".color(fg.yellow) ~ "\nThis is the longest label, but since it's value\nhas multiple lines, it's not taken into account.\n\n" ~
        "Amongst our weapons... Amongst our weaponry... are such elements as fear, surprise... I'll come in again.\n"
    );
}


package string formatApproxDifferences(TReceived, TExpected, F : real)(
    const auto ref TExpected expected,
    const auto ref TReceived received,
    F maxRelDiff = CommonDefaultFor!(TReceived, TExpected),
    F maxAbsDiff = 0.0
)
{
    static string getOrderOperator(real lhs, real rhs)
    {
        if (lhs > rhs)
            return " > ";
        else if (lhs < rhs)
            return " < ";
        else
            return " = ";
    }

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


package string formatTypeDifferences(TypeInfo expected, TypeInfo received, bool not)
{
    static string indentAllExceptFirst(string text, int numSpaces)
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

    return formatDifferences(
        prettyPrint(expected),
        indentAllExceptFirst(
            prettyPrintInheritanceTree(received),
            not ? 11 : 10
        ),
        not
    );
}


/// Converts an array of orderable elements into English.
///
/// - Given `[]` returns `""`
/// - Given `[1]` returns `"1"`
/// - Given `[3, 0]` returns `"0 and 3"`
/// - Given `[1, 0, 3]` returns `"0, 1, and 3"`
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
