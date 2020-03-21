module exceeds_expections.test.to_equal;

import exceeds_expections;
import exceeds_expections.test;

import std.conv;


unittest
{
    showMessage(expect(2).toEqual(3));
}

unittest
{
    showMessage(expect(float(2.5)).toEqual(real(2.12)));
}

unittest
{
    import std.datetime : Date, SysTime;
    showMessage(expect(Date(2020, 3, 25)).toEqual(Date(2020, 3, 15)));
}

unittest
{
    class A
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

    expect(new A(4)).toEqual(new A(4));
    expect(new A(7)).toEqual(new A(8));
}
