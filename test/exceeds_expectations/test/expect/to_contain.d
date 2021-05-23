module exceeds_expectations.test.expect.to_contain;

import exceeds_expectations;
import exceeds_expectations.test;
import std.algorithm;
import std.range;


@("empty array failure")
unittest
{
    string[] arr = [];

    shouldFail(
        expect(arr).toContain("nothing at all")
    );
}

@("single element array success")
unittest
{
    expect([6]).toContain(6);
}

@("single element array failure")
unittest
{
    shouldFail(
        expect([6]).toContain(4)
    );
}

@("several element array success")
unittest
{
    expect(["☿", "♀", "♁", "♂", "♃", "♄", "⛢", "♆"]).toContain("♁");
}

@("several element array failure")
unittest
{
    shouldFail(
        expect(["☿", "♀", "♁", "♂", "♃", "♄", "⛢", "♆"]).toContain("♇")
    );
}

@("classes")
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
    }

    shouldFail(
        expect([new Point(-1, 5, 9), new Point(7, 8, 7), new Point(-5, -3, -3)]).toContain(new Point(0, 0, 0))
    );
}

@("sub-array")
unittest
{
    expect(iota(20).array).toContain([7, 8, 9, 10]);
}

@("sub-array failure")
unittest
{
    shouldFail(
        expect(iota(20).array).toContain([13, 12])
    );
}

@("predicate success")
unittest
{
    expect([2, 4, 6, 8, 10, 11]).toContain((int e) => e % 2 == 1);
}

@("predicate failure")
unittest
{
    shouldFail(
        expect([2, 4, 6, 8, 10]).toContain((int e) => e % 2 == 1)
    );
}
