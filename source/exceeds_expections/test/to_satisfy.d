module exceeds_expections.test.to_satisfy;

import exceeds_expections;
import exceeds_expections.test;

@("Integer satisfy 1/1")
unittest
{
    shouldFail(expect(45).toSatisfy(a => a < 32 && a > 23));
}

@("Class satisfy 1/1")
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

@("Integer satisfyAll 3/3")
unittest
{
    expect(5).toSatisfyAll(
        e => e < 10,
        e => e > 2,
        e => e % 2 == 1
    );
}

@("Integer satisfyAll 2/3")
unittest
{
    shouldFail(
        expect(5).toSatisfyAll(
            e => e < 10,
            e => e > 8,
            e => e % 2 == 1
        )
    );
}

@("Integer satisfyAll 2/3")
unittest
{
    shouldFail(
        expect(5).toSatisfyAll(
            e => e < 3,
            e => e > 8,
            e => e % 2 == 1
        )
    );

}

@("Integer satisfyAll 3/4")
unittest
{
    shouldFail(
        expect(5).toSatisfyAll(
            e => e < 3,
            e => e > 8,
            e => e % 2 == 0,
            e => true
        )
    );

    // All failures
    shouldFail(
        expect(5).toSatisfyAll(
            e => e < 3,
            e => e > 8,
            e => e % 2 == 0,
            e => false
        )
    );
}

@("Integer satisfyAny 3/3")
unittest
{
    expect(0).toSatisfyAll(i => i < 100, i => i > -1, i => i == 0);
}

@("Integer satisfyAny 2/3")
unittest
{
    // Passes
    expect(5).toSatisfyAny(
        e => e < 10,
        e => e > 9,
        e => e % 2 == 1
    );
}

@("Integer satisfyAny 0/3")
unittest
{
    // Fails
    shouldFail(
        expect(5).toSatisfyAny(
            e => e < 3,
            e => e > 9,
            e => e % 2 == 0
        )
    );
}

@("char satifsfyAny 1/2")
unittest
{
    expect('c').toSatisfyAny(c => c == 'c', c => c == 'd');
}
