module exceeds_expections.test.to_equal;

import exceeds_expections;
import exceeds_expections.test;

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
