module exceeds_expectations.test.expect_not.to_contain;

import exceeds_expectations;
import exceeds_expectations.test;
import std.range;


@("toContain empty array")
unittest
{
    int[] arr = [];
    expect(arr).not.toContain([4]);
}

@("toContain single element array")
unittest
{
    expect([6]).not.toContain(4);
}

@("toContain single element array, but does")
unittest
{
    shouldFail(
        expect([6]).not.toContain(6)
    );
}

@("toContain several element array")
unittest
{
    expect(["☿", "♀", "♁", "♂", "♃", "♄", "⛢", "♆"]).not.toContain("♇");
}

@("toContain several element array, but does")
unittest
{
    shouldFail(
        expect(["☿", "♀", "♁", "♂", "♃", "♄", "⛢", "♆"]).not.toContain("♁")
    );
}

@("toContain classes, but does")
unittest
{
    class Point
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

        override bool opEquals(Object other) const
        {
            if (!cast(Point) other) return false;

            return (
                this.x == (cast(Point)other).x &&
                this.y == (cast(Point)other).y &&
                this.z == (cast(Point)other).z
            );
        }
    }

    shouldFail(
        expect(
            [new Point(-1, 5, 9), new Point(7, 8, 7), new Point(-5, -3, -3)]
        ).not.toContain(new Point(7, 8, 7))
    );
}

@("toContain sub-array")
unittest
{
    expect(iota(20).array).not.toContain([7, 9, 8, 10]);
}

@("toContain sub-array, but does")
unittest
{
    shouldFail(
        expect(iota(20).array).not.toContain([10, 11, 12])
    );
}

@("toContain predicate")
unittest
{
    expect(iota(20).array).not.toContain((int e) => e < 0);
}

@("toContain predicate, but does")
unittest
{
    shouldFail(
        expect(iota(20).array).not.toContain((int e) => e % 2 == 0)
    );
}
