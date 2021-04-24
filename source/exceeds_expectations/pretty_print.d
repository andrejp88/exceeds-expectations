module exceeds_expectations.pretty_print;

import colorize;
import exceeds_expectations;
import std.algorithm;
import std.conv;
import std.range;
import std.string;
import std.traits;


package string prettyPrint(T)(T value)
{
    string rawStringified;

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



private string prettyPrintClassObject(T)(const T object)
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

private class TestClass {}
private interface TestInterface {}
private struct TestStruct {}
private enum TestEnum { TestEnumValue }
private enum int testEnumConst = 4;

@("prettyPrintTypeInfo — class")
unittest
{
    expect(prettyPrintTypeInfo(typeid(TestClass))).toEqual("exceeds_expectations.pretty_print.TestClass");
    expect(prettyPrintTypeInfo(TestClass.classinfo)).toEqual("exceeds_expectations.pretty_print.TestClass");
    expect(prettyPrintTypeInfo(typeid(new TestClass()))).toEqual("exceeds_expectations.pretty_print.TestClass");
    expect(prettyPrintTypeInfo((new TestClass()).classinfo)).toEqual("exceeds_expectations.pretty_print.TestClass");
}

@("prettyPrintTypeInfo — interface")
unittest
{
    expect(prettyPrintTypeInfo(TestInterface.classinfo)).toEqual("exceeds_expectations.pretty_print.TestInterface");
}

@("prettyPrintTypeInfo — struct")
unittest
{
    expect(prettyPrintTypeInfo(typeid(TestStruct))).toEqual("exceeds_expectations.pretty_print.TestStruct");
    expect(prettyPrintTypeInfo(typeid(TestStruct()))).toEqual("exceeds_expectations.pretty_print.TestStruct");
}

@("prettyPrintTypeInfo — int")
unittest
{
    expect(prettyPrintTypeInfo(typeid(int))).toEqual("int");
}

@("prettyPrintTypeInfo — string")
unittest
{
    expect(prettyPrintTypeInfo(typeid("Hello World"))).toEqual("string");
}

@("prettyPrintTypeInfo — static array")
unittest
{
    expect(prettyPrintTypeInfo(typeid(int[3]))).toEqual("int[3]");
    expect(prettyPrintTypeInfo(typeid(TestClass[3]))).toEqual("exceeds_expectations.pretty_print.TestClass[3]");
    expect(prettyPrintTypeInfo(typeid(TestInterface[3]))).toEqual("exceeds_expectations.pretty_print.TestInterface[3]");
}

@("prettyPrintTypeInfo — dynamic array")
unittest
{
    expect(prettyPrintTypeInfo(typeid(int[]))).toEqual("int[]");
    expect(prettyPrintTypeInfo(typeid(TestClass[]))).toEqual("exceeds_expectations.pretty_print.TestClass[]");
    expect(prettyPrintTypeInfo(typeid(TestInterface[]))).toEqual("exceeds_expectations.pretty_print.TestInterface[]");
}

@("prettyPrintTypeInfo — enum")
unittest
{
    expect(prettyPrintTypeInfo(typeid(TestEnum))).toEqual("exceeds_expectations.pretty_print.TestEnum");
    expect(prettyPrintTypeInfo(typeid(TestEnum.TestEnumValue))).toEqual("exceeds_expectations.pretty_print.TestEnum");
    expect(prettyPrintTypeInfo(typeid(testEnumConst))).toEqual("int");
}

@("prettyPrintTypeInfo — associative array")
unittest
{
    expect(prettyPrintTypeInfo(typeid(int[string]))).toEqual("int[string]");
    expect(prettyPrintTypeInfo(typeid(TestClass[TestInterface]))).toEqual(
        "exceeds_expectations.pretty_print.TestClass[exceeds_expectations.pretty_print.TestInterface]"
    );
    expect(prettyPrintTypeInfo(typeid(TestInterface[TestClass]))).toEqual(
        "exceeds_expectations.pretty_print.TestInterface[exceeds_expectations.pretty_print.TestClass]"
    );
}

@("prettyPrintTypeInfo — pointer")
unittest
{
    expect(prettyPrintTypeInfo(typeid(TestStruct*))).toEqual("exceeds_expectations.pretty_print.TestStruct*");
}

@("prettyPrintTypeInfo — function")
unittest
{
    expect(prettyPrintTypeInfo(typeid(TestClass function(TestInterface ti)))).toEqual(
        "exceeds_expectations.pretty_print.TestClass function(exceeds_expectations.pretty_print.TestInterface)*"
    );

    static int testFn(float x) { return 0; }
    expect(prettyPrintTypeInfo(typeid(&testFn))).toEqual(
        "int function(float) pure nothrow @nogc @safe*"
    );

    TestStruct* function(int[string]) testFnVar = (aa) => new TestStruct();
    expect(prettyPrintTypeInfo(typeid(testFnVar))).toEqual(
        "exceeds_expectations.pretty_print.TestStruct* function(int[string])*"
    );

    expect(prettyPrintTypeInfo(typeid((string s) => 3))).toEqual("int function(string) pure nothrow @nogc @safe*");
}

@("prettyPrintTypeInfo — delegate")
unittest
{
    expect(prettyPrintTypeInfo(typeid(TestClass delegate(TestInterface ti)))).toEqual(
        "exceeds_expectations.pretty_print.TestClass delegate(exceeds_expectations.pretty_print.TestInterface)"
    );

    int y = 4;
    int testDg(float x) { return y; }
    expect(prettyPrintTypeInfo(typeid(&testDg))).toEqual(
        "int delegate(float) pure nothrow @nogc @safe"
    );

    string[string] delegate(TestInterface[]) testDgVar = (arr) => ["hello": "world"];
    expect(prettyPrintTypeInfo(typeid(testDgVar))).toEqual(
        "string[string] delegate(exceeds_expectations.pretty_print.TestInterface[])"
    );

    immutable int z = 5;
    expect(prettyPrintTypeInfo(typeid((string _) => cast(int)z))).toEqual(
        "int delegate(string) pure nothrow @nogc @safe"
    );
}

@("prettyPrintTypeInfo — tuple (AliasSeq)")
unittest
{
    // import std.typecons : tuple, Tuple;
    import std.meta : AliasSeq;
    expect(prettyPrintTypeInfo(typeid(AliasSeq!(string, int, TestStruct*)))).toEqual(
        "(string, int, exceeds_expectations.pretty_print.TestStruct*)"
    );
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

private class Class1 {}
private interface Interface1 {}

@("prettyPrintInheritanceTree — Simple class")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Class1))).toEqual(
        "exceeds_expectations.pretty_print.Class1"
    );
}

@("prettyPrintInheritanceTree — Simple interface")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Interface1))).toEqual(
        "exceeds_expectations.pretty_print.Interface1"
    );
}

private class Class2 : Class1 {}

@("prettyPrintInheritanceTree — class extending class")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Class2))).toEqual(
        "exceeds_expectations.pretty_print.Class2\n" ~
        "<: exceeds_expectations.pretty_print.Class1"
    );
}

private class Class3 : Interface1 {}

@("prettyPrintInheritanceTree — class implementing interface")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Class3))).toEqual(
        "exceeds_expectations.pretty_print.Class3\n" ~
        "<: exceeds_expectations.pretty_print.Interface1"
    );
}

private interface Interface2 {}
private class Class4 : Interface1, Interface2 {}

@("prettyPrintInheritanceTree — class implementing 2 interfaces")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Class4))).toEqual(
        "exceeds_expectations.pretty_print.Class4\n" ~
        "<: exceeds_expectations.pretty_print.Interface1\n" ~
        "<: exceeds_expectations.pretty_print.Interface2"
    );
}

private class Class5 : Class1, Interface1 {}

@("prettyPrintInheritanceTree — class extending a class and implementing an interface")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Class5))).toEqual(
        "exceeds_expectations.pretty_print.Class5\n" ~
        "<: exceeds_expectations.pretty_print.Class1\n" ~
        "<: exceeds_expectations.pretty_print.Interface1"
    );
}

private class Class6 : Class2 {}

@("prettyPrintInheritanceTree — class extending class extending class")
unittest
{
    expect(prettyPrintInheritanceTree(typeid(Class6))).toEqual(
        "exceeds_expectations.pretty_print.Class6\n" ~
        "<: exceeds_expectations.pretty_print.Class2\n" ~
        "   <: exceeds_expectations.pretty_print.Class1"
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
        "exceeds_expectations.pretty_print.CBC3C\n" ~
        "<: exceeds_expectations.pretty_print.CB3\n" ~
        "   <: exceeds_expectations.pretty_print.IB\n" ~
        "   <: exceeds_expectations.pretty_print.I3\n" ~
        "<: exceeds_expectations.pretty_print.ICC\n" ~
        "   <: exceeds_expectations.pretty_print.IC"
    );
}
