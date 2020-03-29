module exceeds_expections.test.to_satisfy;

import exceeds_expections;
import exceeds_expections.test;

unittest
{
    showMessage(expect(45).toSatisfy(a => a < 32 && a > 23));
}

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

unittest
{
    // No failures
    expect(5).toSatisfyAll(
        e => e < 10,
        e => e > 2,
        e => e % 2 == 1
    );

    // One failure
    showMessage(
        expect(5).toSatisfyAll(
            e => e < 10,
            e => e > 8,
            e => e % 2 == 1
        )
    );

    // Two failures
    showMessage(
        expect(5).toSatisfyAll(
            e => e < 3,
            e => e > 8,
            e => e % 2 == 1
        )
    );

    // Three failures
    showMessage(
        expect(5).toSatisfyAll(
            e => e < 3,
            e => e > 8,
            e => e % 2 == 0,
            e => true
        )
    );

    // All failures
    showMessage(
        expect(5).toSatisfyAll(
            e => e < 3,
            e => e > 8,
            e => e % 2 == 0,
            e => false
        )
    );
}

unittest
{
    // Passes
    expect(5).toSatisfyAny(
        e => e < 10,
        e => e > 9,
        e => e % 2 == 1
    );

    // Fails
    showMessage(
        expect(5).toSatisfyAny(
            e => e < 3,
            e => e > 9,
            e => e % 2 == 0
        )
    );
}

unittest
{
    expect(5).toSatisfy(e => e == 5);
    expect('c').toSatisfyAny(c => c == 'c', c => c == 'd');
    expect(0).toSatisfyAll(i => i < 100, i => i > -1, i => i == 0);
}
