module exceeds_expectations.test.expect.to_satisfy;

import exceeds_expectations;
import exceeds_expectations.test;


@("Integer success")
unittest
{
    expect(45).toSatisfy(a => a % 2 == 1);
}

@("Integer failure")
unittest
{
    shouldFail(expect(45).toSatisfy(a => a < 32 && a > 23));
}

private class A
{
    real x;
    real y;
    real z;

    this (real x, real y, real z)
    {
        this.x = x;
        this.y = y;
        this.z = z;
    }
}

@("Class success")
unittest
{
    import std.math : sqrt;
    expect(new A(2, 3, 6)).toSatisfy(a => sqrt(a.x * a.x + a.y * a.y + a.z * a.z) == 7);
}

@("Class failure")
unittest
{
    import std.math : sqrt;
    shouldFail(expect(new A(4, 5, 7)).toSatisfy(a => sqrt(a.x * a.x + a.y * a.y + a.z * a.z) == 9));
}

@("Failed due to exception")
unittest
{
    int delegate() dg = { throw new Exception("Oops"); };

    shouldFail(
        expect(dg).toSatisfy(result => result() == 4)
    );
}
