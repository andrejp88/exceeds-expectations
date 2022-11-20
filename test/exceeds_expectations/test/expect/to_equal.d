module exceeds_expectations.test.expect.to_equal;

import exceeds_expectations;
import exceeds_expectations.test;

import std.conv;


@("Integer == Integer")
unittest
{
    expect(2).toEqual(2);
}

@("Integer != Integer")
unittest
{
    shouldFail(expect(2).toEqual(3));
}

@("Floating point == Floating Point")
unittest
{
    expect(float(2.5)).toEqual(float(2.5));
}

@("float == real")
unittest
{
    expect(float(2.5)).toEqual(real(2.5));
}

@("Floating point != Floating point")
unittest
{
    shouldFail(expect(float(2.5)).toEqual(float(2.12)));
}

@("float == int")
unittest
{
    expect(2.0f).toEqual(2);
}

@("float != string")
unittest
{
    static assert(!__traits(compiles, expect(2.0f).toEqual("two")));
}

@("Struct == Struct")
unittest
{
    import std.datetime : Date, SysTime;
    expect(Date(2020, 3, 25)).toEqual(Date(2020, 3, 25));
}

@("Struct != Struct")
unittest
{
    import std.datetime : Date;
    shouldFail(expect(Date(2020, 3, 25)).toEqual(Date(2020, 2, 17)));
}

private class A // @suppress(dscanner.suspicious.incomplete_operator_overloading)
{
    int x;

    this(int x) { this.x = x; }

    override bool opEquals(Object other)
    const
    {
        const(typeof(this)) other_ = cast(typeof(this)) other;
        return other_ && this.x == other_.x;
    }


}

@("Class == Class")
unittest
{
    expect(new A(4)).toEqual(new A(4));
}

@("Class != Class")
unittest
{
    shouldFail(expect(new A(7)).toEqual(new A(8)));
}

@("string != empty string")
unittest
{
    shouldFail(expect("").toEqual("non-empty"));
    shouldFail(expect("non-empty").toEqual(""));
}

@("multiline strings")
unittest
{
    shouldFail(expect(`
Hello World.
`).toEqual(`Hello
World.`));
}

@("wstrings (UTF-16)")
unittest
{
    expect("Hello World"w).toEqual("Hello World"w);
}

@("dstrings (UTF-32)")
unittest
{
    expect("Hello World"d).toEqual("Hello World"d);
}

@("Don't over-strip trailing zeroes")
unittest
{
    shouldFail(expect(4.0).toEqual(40.0));
}

@("Arrays")
unittest
{
    string[] witches = ["Esmerelda Weatherwax", "Gytha Ogg", "Magrat Garlick"];

    expect(witches).toEqual(["Esmerelda Weatherwax", "Gytha Ogg", "Magrat Garlick"]);
}

@("Associative arrays")
unittest
{
    string[string] aa = [
        "name": "Mustrum",
        "surname": "Ridcully",
    ];

    expect(aa).toEqual([
        "name": "Mustrum",
        "surname": "Ridcully",
    ]);
}

@("Structs with associative arrays")
unittest
{
    struct S
    {
        string[string] aa;
    }

    S s1 = S(["name": "Rincewind"]);

    expect(s1).toEqual(S([
        "name": "Rincewind",
    ]));
}

@("Weird struct with a non-const toEquals")
unittest
{
    struct Weird
    {
        int x;
        uint opEqualsCallCount;

        bool opEquals(R)(R other)
        {
            opEqualsCallCount++;
            return this.x == other.x;
        }
    }

    Weird w = Weird(2);

    expect(w).toEqual(Weird(2));
}
