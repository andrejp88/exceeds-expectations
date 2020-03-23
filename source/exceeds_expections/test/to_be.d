module exceeds_expections.test.to_be;

import exceeds_expections;
import exceeds_expections.test;

import std.conv;

unittest
{
    class C {}

    C c = new C();
    C c2 = c;

    expect(c2).toBe(c);
    expect(5).toBe(5);
}

unittest
{
    class C {}
    C c = new C;
    C c2 = new C;

    showMessage(expect(c).toBe(c2));
}

unittest
{
    int delegate(int) f = i => i + 1;
    int delegate(int) g = i => i - 1;

    showMessage(expect(f).toBe(g));
}

unittest
{
   showMessage(expect(2).toBe(3));
}
