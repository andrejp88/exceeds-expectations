module exceeds_expectations.test.expect.to_be;

import exceeds_expectations;
import exceeds_expectations.test;
import std.conv;


@("Class is Class")
unittest
{
    class C {}

    C c = new C();
    C c2 = c;

    expect(c2).toBe(c);
    expect(5).toBe(5);
}

@("Class !is Class")
unittest
{
    class C {}
    C c = new C;
    C c2 = new C;

    shouldFail(expect(c).toBe(c2));
}

@("Delegate is Delegate")
unittest
{
    int delegate(int) f = i => i + 1;
    int delegate(int) g = f;

    expect(f).toBe(g);
}

@("Delegate !is Delegate")
unittest
{
    int delegate(int) f = i => i + 1;
    int delegate(int) g = i => i - 1;

    shouldFail(expect(f).toBe(g));
}

@("Integer is Integer")
unittest
{
   expect(2).toBe(2);
}

@("Integer !is Integer")
unittest
{
   shouldFail(expect(2).toBe(3));
}

@("int* is float*")
unittest
{
    int i;
    int* pi = &i;
    float* pf = cast(float*)pi;
    static assert(!__traits(compiles, expect(pi).toBe(pf)));
}
