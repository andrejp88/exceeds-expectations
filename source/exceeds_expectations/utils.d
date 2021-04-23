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


package string formatDifferences(string expected, string received)
{
    string expectedString = "Expected: ".color(fg.green) ~ expected ~ (expected.isMultiline ? "\n" : "");
    string receivedString = "Received: ".color(fg.light_red) ~ received;
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

        "Relative Difference: ".color(fg.yellow) ~
        stringify(relDiff) ~ getOrderOperator(relDiff, maxRelDiff) ~ stringify(maxRelDiff) ~
        " (maxRelDiff)\n" ~

        "Absolute Difference: ".color(fg.yellow) ~
        stringify(absDiff) ~ getOrderOperator(absDiff, maxAbsDiff) ~ stringify(maxAbsDiff) ~
        " (maxAbsDiff)\n";
}

package string formatTypeDifferences(TypeInfo expected, TypeInfo received)
{
    if (TypeInfo_Class tic = cast(TypeInfo_Class) received)
    {
        return formatDifferences(
            formatTypeInfo(expected),
            prettyPrintInheritanceTree(received)
                .splitLines()
                .enumerate()
                .map!((idxValuePair) => idxValuePair[0] == 0 ? idxValuePair[1] : "          " ~ idxValuePair[1])
                .join("\n")
        );
    }

    return formatDifferences(
        formatTypeInfo(expected),
        formatTypeInfo(received)
    );
}

package string formatTypeInfo(TypeInfo typeInfo)
{
    import std.regex : ctRegex, replaceAll;

    string typeName;

    if (TypeInfo_Tuple tiu = cast(TypeInfo_Tuple) typeInfo)
    {
        // The default toString() does not separate the elements with spaces
        typeName = "(" ~
            (
                tiu.elements
                    .map!formatTypeInfo
                    .join(", ")
            ) ~ ")";
    }
    else
    {
        typeName = typeInfo.toString();
    }

    return typeName.replaceAll(ctRegex!`immutable\(char\)\[\]`, "string");
}

private class TestClass {}
private interface TestInterface {}
private struct TestStruct {}
private enum TestEnum { TestEnumValue }
private enum int testEnumConst = 4;

@("formatTypeInfo — class")
unittest
{
    expect(formatTypeInfo(typeid(TestClass))).toEqual("exceeds_expectations.utils.TestClass");
    expect(formatTypeInfo(TestClass.classinfo)).toEqual("exceeds_expectations.utils.TestClass");
    expect(formatTypeInfo(typeid(new TestClass()))).toEqual("exceeds_expectations.utils.TestClass");
    expect(formatTypeInfo((new TestClass()).classinfo)).toEqual("exceeds_expectations.utils.TestClass");
}

@("formatTypeInfo — interface")
unittest
{
    expect(formatTypeInfo(TestInterface.classinfo)).toEqual("exceeds_expectations.utils.TestInterface");
}

@("formatTypeInfo — struct")
unittest
{
    expect(formatTypeInfo(typeid(TestStruct))).toEqual("exceeds_expectations.utils.TestStruct");
    expect(formatTypeInfo(typeid(TestStruct()))).toEqual("exceeds_expectations.utils.TestStruct");
}

@("formatTypeInfo — int")
unittest
{
    expect(formatTypeInfo(typeid(int))).toEqual("int");
}

@("formatTypeInfo — string")
unittest
{
    expect(formatTypeInfo(typeid("Hello World"))).toEqual("string");
}

@("formatTypeInfo — static array")
unittest
{
    expect(formatTypeInfo(typeid(int[3]))).toEqual("int[3]");
    expect(formatTypeInfo(typeid(TestClass[3]))).toEqual("exceeds_expectations.utils.TestClass[3]");
    expect(formatTypeInfo(typeid(TestInterface[3]))).toEqual("exceeds_expectations.utils.TestInterface[3]");
}

@("formatTypeInfo — dynamic array")
unittest
{
    expect(formatTypeInfo(typeid(int[]))).toEqual("int[]");
    expect(formatTypeInfo(typeid(TestClass[]))).toEqual("exceeds_expectations.utils.TestClass[]");
    expect(formatTypeInfo(typeid(TestInterface[]))).toEqual("exceeds_expectations.utils.TestInterface[]");
}

@("formatTypeInfo — enum")
unittest
{
    expect(formatTypeInfo(typeid(TestEnum))).toEqual("exceeds_expectations.utils.TestEnum");
    expect(formatTypeInfo(typeid(TestEnum.TestEnumValue))).toEqual("exceeds_expectations.utils.TestEnum");
    expect(formatTypeInfo(typeid(testEnumConst))).toEqual("int");
}

@("formatTypeInfo — associative array")
unittest
{
    expect(formatTypeInfo(typeid(int[string]))).toEqual("int[string]");
    expect(formatTypeInfo(typeid(TestClass[TestInterface]))).toEqual(
        "exceeds_expectations.utils.TestClass[exceeds_expectations.utils.TestInterface]"
    );
    expect(formatTypeInfo(typeid(TestInterface[TestClass]))).toEqual(
        "exceeds_expectations.utils.TestInterface[exceeds_expectations.utils.TestClass]"
    );
}

@("formatTypeInfo — pointer")
unittest
{
    expect(formatTypeInfo(typeid(TestStruct*))).toEqual("exceeds_expectations.utils.TestStruct*");
}

@("formatTypeInfo — function")
unittest
{
    expect(formatTypeInfo(typeid(TestClass function(TestInterface ti)))).toEqual(
        "exceeds_expectations.utils.TestClass function(exceeds_expectations.utils.TestInterface)*"
    );

    static int testFn(float x) { return 0; }
    expect(formatTypeInfo(typeid(&testFn))).toEqual(
        "int function(float) pure nothrow @nogc @safe*"
    );

    TestStruct* function(int[string]) testFnVar = (aa) => new TestStruct();
    expect(formatTypeInfo(typeid(testFnVar))).toEqual(
        "exceeds_expectations.utils.TestStruct* function(int[string])*"
    );

    expect(formatTypeInfo(typeid((string s) => 3))).toEqual("int function(string) pure nothrow @nogc @safe*");
}

@("formatTypeInfo — delegate")
unittest
{
    expect(formatTypeInfo(typeid(TestClass delegate(TestInterface ti)))).toEqual(
        "exceeds_expectations.utils.TestClass delegate(exceeds_expectations.utils.TestInterface)"
    );

    int y = 4;
    int testDg(float x) { return y; }
    expect(formatTypeInfo(typeid(&testDg))).toEqual(
        "int delegate(float) pure nothrow @nogc @safe"
    );

    string[string] delegate(TestInterface[]) testDgVar = (arr) => ["hello": "world"];
    expect(formatTypeInfo(typeid(testDgVar))).toEqual(
        "string[string] delegate(exceeds_expectations.utils.TestInterface[])"
    );

    int z = 5;
    expect(formatTypeInfo(typeid((string s) => z))).toEqual("int delegate(string) pure nothrow @nogc @safe");
}

@("formatTypeInfo — tuple (AliasSeq)")
unittest
{
    // import std.typecons : tuple, Tuple;
    import std.meta : AliasSeq;
    expect(formatTypeInfo(typeid(AliasSeq!(string, int, TestStruct*)))).toEqual(
        "(string, int, exceeds_expectations.utils.TestStruct*)"
    );
}

private string prettyPrintInheritanceTree(TypeInfo typeInfo, int indentLevel = 0)
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

        return formatTypeInfo(typeInfo) ~ superClassesTrace;
    }

    return formatTypeInfo(typeInfo);
}

private class Class1 {}
private interface Interface1 {}

@("prettyPrintInheritanceTree — Simple class")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Class1))).toEqual(
        "exceeds_expectations.utils.Class1"
    );
}

@("prettyPrintInheritanceTree — Simple interface")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Interface1))).toEqual(
        "exceeds_expectations.utils.Interface1"
    );
}

private class Class2 : Class1 {}

@("prettyPrintInheritanceTree — class extending class")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Class2))).toEqual(
        "exceeds_expectations.utils.Class2\n" ~
        "<: exceeds_expectations.utils.Class1"
    );
}

private class Class3 : Interface1 {}

@("prettyPrintInheritanceTree — class implementing interface")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Class3))).toEqual(
        "exceeds_expectations.utils.Class3\n" ~
        "<: exceeds_expectations.utils.Interface1"
    );
}

private interface Interface2 {}
private class Class4 : Interface1, Interface2 {}

@("prettyPrintInheritanceTree — class implementing 2 interfaces")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Class4))).toEqual(
        "exceeds_expectations.utils.Class4\n" ~
        "<: exceeds_expectations.utils.Interface1\n" ~
        "<: exceeds_expectations.utils.Interface2"
    );
}

private class Class5 : Class1, Interface1 {}

@("prettyPrintInheritanceTree — class extending a class and implementing an interface")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Class5))).toEqual(
        "exceeds_expectations.utils.Class5\n" ~
        "<: exceeds_expectations.utils.Class1\n" ~
        "<: exceeds_expectations.utils.Interface1"
    );
}

private class Class6 : Class2 {}

@("prettyPrintInheritanceTree — class extending class extending class")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Class6))).toEqual(
        "exceeds_expectations.utils.Class6\n" ~
        "<: exceeds_expectations.utils.Class2\n" ~
        "   <: exceeds_expectations.utils.Class1"
    );
}

private interface I1 {}
private interface I2 {}
private interface I3 {}
private interface IA {}
private interface IB {}
private interface IC {}
private interface ICC : IC {}

private class CA : IA {}
private class CB3 : IB, I3 {}
private class CBC3C : CB3, ICC {}
private class CAC2 : CA, IC, I2 {}

@("prettyPrintInheritanceTree — A complicated inheritance tree")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(CBC3C))).toEqual(
        "exceeds_expectations.utils.CBC3C\n" ~
        "<: exceeds_expectations.utils.CB3\n" ~
        "   <: exceeds_expectations.utils.IB\n" ~
        "   <: exceeds_expectations.utils.I3\n" ~
        "<: exceeds_expectations.utils.ICC\n" ~
        "   <: exceeds_expectations.utils.IC"
    );
}


private string getOrderOperator(L, R)(L lhs, R rhs)
{
    return lhs > rhs ? " > " : lhs < rhs ? " < " : " = ";
}


package string stringify(T)(T value)
{
    string rawStringified;

    static if (is(T == class) && !__traits(isOverrideFunction, T.toString))
    {
        rawStringified = stringifyClassObject(value);
    }
    else static if (isFloatingPoint!T)
    {
        string asString = "%.14f".format(value);
        rawStringified = asString.canFind('.') ? asString.stripRight("0.") : asString;
    }
    else static if (isSomeString!T)
    {
        rawStringified = (
            `"`.color(fg.init, bg.init, mode.bold) ~
            value ~
            `"`.color(fg.init, bg.init, mode.bold)
        );
    }
    else
    {
        rawStringified = value.to!string;
    }

    if (rawStringified == "") rawStringified = value.to!string; // TODO: unnecessary?

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
