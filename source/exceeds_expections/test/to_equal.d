module exceeds_expections.test.to_equal;

import exceeds_expections;
import exceeds_expections.test;

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

@("Struct == Struct")
unittest
{
    import std.datetime : Date, SysTime;
    expect(Date(2020, 3, 25)).toEqual(Date(2020, 3, 25));
}

@("Struct != Struct")
unittest
{
    import std.datetime : Date, SysTime;
    shouldFail(expect(Date(2020, 3, 25)).toEqual(Date(2020, 2, 17)));
}

private class A
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
