module exceeds_expectations.pretty_print;

import colorize;
import exceeds_expectations;
import std.algorithm;
import std.conv;
import std.range;
import std.string;
import std.traits;


/// Prints the given value in a nice, human readable format. If
/// receiving a string, it will output the string with bold double
/// quotes indicating the start and end of the string. The returned
/// string will never start nor end with a line break.
package string prettyPrint(T)(T value, bool skipColoring = false)
out(result; (!result.endsWith("\n") && !result.startsWith("\n")))
{
    string rawStringified;

    alias ColorFunc = typeof(&color);

    ColorFunc customColor = (
        skipColoring ?
        ((str, c, b, m) => str) :
        &color
    );

    static if (is(T == class) && !__traits(isOverrideFunction, T.toString))
    {
        if (TypeInfo typeInfo = cast(TypeInfo) value)
        {
            rawStringified = prettyPrintTypeInfo(typeInfo);
        }

        rawStringified = prettyPrintObjectFields(value);
    }
    else static if (is(T == struct) && !__traits(hasMember, T, "toString"))
    {
        rawStringified = prettyPrintObjectFields(value);
    }
    else static if (isFloatingPoint!T)
    {
        string asString = "%.14f".format(value);
        rawStringified = asString.canFind('.') ? asString.stripRight("0").stripRight(".") : asString;  // Strip trailing zeroes and decimal points
    }
    else static if (isSomeString!T)
    {
        rawStringified = (
            customColor(`"`, fg.init, bg.init, mode.bold) ~
            value ~
            customColor(`"`, fg.init, bg.init, mode.bold)
        );
    }
    else static if (isArray!T)
    {
        alias E = ElementType!T;
        static if (isStaticArray!T)
        {
            E[] slice = value[];
        }
        else
        {
            E[] slice = value;
        }

        auto elements = slice.map!(e => prettyPrint(e, true));

        rawStringified = (
            "[" ~
                (
                    elements.any!(e => e.canFind("\n")) ?
                    ("\n" ~ elements.map!(e => indent(e, 4)).join("\n") ~ "\n") :
                    elements.join(", ")
                ) ~
            "]"
        );
    }
    else
    {
        rawStringified = value.to!string;
    }

    return rawStringified.strip("\n");
}


package string prettyPrintHighlightedArray(T)(T arr, size_t[2][] ranges = [])
if (isArray!T)
in (ranges.all!(e => e[1] > e[0]), "All ranges must have the second element greater than the first.")
out (result; !result.endsWith("\n") && !result.startsWith("\n"))
{
    alias E = ElementType!T;

    static string printRange(E[] arr)
    {
        auto elements = arr.map!(e => prettyPrint(e, true));

        return (
            elements.any!(e => e.canFind("\n")) ?
            elements.map!(e => indent(e, 4)).join("\n") :
            elements.join(", ")
        );
    }

    size_t[2][] rangesSortedByMin = sort!((a, b) => a[0] < b[0])(ranges).array;
    size_t[2][] mergedRanges = mergeOverlappingRanges(rangesSortedByMin);

    size_t lastEnding = 0;
    string[] chunks;
    foreach (size_t i, size_t[2] range; mergedRanges)
    {
        if (range[0] != lastEnding)
        {
            chunks ~= printRange(arr[lastEnding .. range[0]]);
        }

        chunks ~=
            printRange(arr[range[0] .. range[1]]).color(fg.black, bg.yellow)
            .splitLines()
            .map!(e => e.color(fg.black, bg.yellow))
            .join("\n");

        lastEnding = range[1];

        if ((i + 1) == mergedRanges.length && range[1] != arr.length)
        {
            chunks ~= printRange(arr[range[1] .. $]);
        }
    }

    if (mergedRanges.length == 0)
    {
        chunks ~= printRange(arr);
    }

    immutable bool isMultiline = chunks.any!(c => c.canFind('\n'));
    string[] result;
    result ~= "[";
    result ~= chunks.join(isMultiline ? "\n" : ", ");
    result ~= "]";

    return result.join(isMultiline ? "\n" : "");
}


package size_t[2][] mergeOverlappingRanges(const size_t[2][] input)
in (input.isSorted!((a, b) => a[0] < b[0]), "mergeOverlappingRanges expects the input to be sorted")
out (result; result.length <= input.length)
{
    size_t[2][] result;

    foreach (size_t i, size_t[2] range; input)
    {
        if (
            i != 0 &&
            range[0] < result[$ - 1][1]
        )
        {
            if (range[1] > result[$ - 1][1])
            {
                result[$ - 1][1] = range[1];
            }
        }
        else
        {
            result ~= range;
        }
    }

    return result;
}


private string prettyPrintObjectFields(T)(const T object)
if (
    is(T == class) ||
    is(T == struct)
)
out(result; result.endsWith("\n") && !(result.startsWith("\n")))
{
    import std.range : Appender;

    Appender!string output;

    output.put(
        is(T == class) ? "class " :
        is(T == struct) ? "struct " :
        ""
    );
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

    output.put("}\n");

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


package string prettyPrintTypeInfo(TypeInfo typeInfo)
{
    import std.regex : ctRegex, replaceAll;

    string typeName;

    if (TypeInfo_Tuple tiu = cast(TypeInfo_Tuple) typeInfo)
    {
        // The default toString() does not separate the elements with spaces
        typeName = "(" ~
            (
                tiu.elements
                    .map!prettyPrintTypeInfo
                    .join(", ")
            ) ~ ")";
    }
    else
    {
        typeName = typeInfo.toString();
    }

    return typeName.replaceAll(ctRegex!`immutable\(char\)\[\]`, "string");
}


package string prettyPrintInheritanceTree(TypeInfo typeInfo, int indentLevel = 0)
{
    expect(typeInfo).toSatisfyAny(
        (const TypeInfo it) => (cast(TypeInfo_Class) it) !is null,
        (const TypeInfo it) => (cast(TypeInfo_Interface) it) !is null,
    );

    if (TypeInfo_Class tic = cast(TypeInfo_Class) typeInfo)
    {
        string superClassesTrace;

        string indentation = ' '.repeat(3 * indentLevel).array;

        if (tic.base !is null && tic.base != typeid(Object))
        {
            superClassesTrace ~= "\n" ~ indentation ~ "<: " ~ prettyPrintInheritanceTree(tic.base, indentLevel + 1);
        }

        foreach (Interface i; tic.interfaces)
        {
            superClassesTrace ~= "\n" ~ indentation ~ "<: " ~ prettyPrintInheritanceTree(i.classinfo, indentLevel + 1);
        }

        return prettyPrintTypeInfo(typeInfo) ~ superClassesTrace;
    }

    return prettyPrintTypeInfo(typeInfo);
}


private string indent(string text, int numSpaces)
{
    return text
        .splitLines(Yes.keepTerminator)
        .map!(
            line => (
                ' '.repeat(numSpaces).array.to!string ~ line
            )
        )
        .join();
}


package string prettyPrintComparison(real lhs, real rhs)
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

    return prettyPrint(lhs) ~ getOrderOperator(lhs, rhs) ~ prettyPrint(rhs);
}


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


package string convertTabsToSpaces(string line)
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


package string truncate(string line, int length)
in(length >= 0, "Cannot truncate line to length " ~ length.to!string)
{
    if (line.length > length)
    {
        return line[0 .. length - 4] ~ " ...".color(fg.light_black);
    }

    return line;
}

/// Returns a string showing the expected and received values. Ends
/// with a line separator.
package string formatDifferences(string expected, string received, bool not)
{
    immutable string lineLabel1 = (not ? "Forbidden: " : "Expected: ").color(fg.green);
    immutable string lineLabel2 = (not ? "Received:  " : "Received: ").color(fg.red);
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
                i == 0 ? fg.green :
                i == 1 ? fg.red :
                fg.yellow
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
