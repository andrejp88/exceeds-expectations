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

        rawStringified = prettyPrintClassObject(value);
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
            printRange(arr[range[0] .. range[1]]).color(bg.yellow)
            .splitLines()
            .map!(e => e.color(bg.yellow))
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


private size_t[2][] mergeOverlappingRanges(const size_t[2][] input)
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


private string prettyPrintClassObject(T)(const T object)
if (is(T == class))
out(result; result.endsWith("\n") && !(result.startsWith("\n")))
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


private string prettyPrintTypeInfo(TypeInfo typeInfo)
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
