module exceeds_expections.test.to_satisfy;

import exceeds_expections;
import exceeds_expections.test;

@("Integer failure")
unittest
{
    shouldFail(expect(45).toSatisfy(a => a < 32 && a > 23));
}

@("Class success")
unittest
{
    import std.math : sqrt;

    class A
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

    expect(new A(2, 3, 6)).toSatisfy(a => sqrt(a.x * a.x + a.y * a.y + a.z * a.z) == 7);
}
