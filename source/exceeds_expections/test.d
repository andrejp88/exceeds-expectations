module exceeds_expectations.test;

import exceeds_expections;

unittest
{
    import std.datetime : Date, SysTime;
    expect(2).toEqual(2);
    expect(Date(2020, 3, 25)).toEqual(Date(2020, 3, 15));
}
