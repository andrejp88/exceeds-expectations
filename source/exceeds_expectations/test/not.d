module exceeds_expectations.test.not;

import exceeds_expectations;
import exceeds_expectations.test;
import std.range;


@("toEqual")
unittest
{
    expect(4).not.toEqual(5);
}

@("toEqual, but does")
unittest
{
    shouldFail(expect(4).not.toEqual(4));
}

@("toBe")
unittest
{
    expect(4).not.toBe(5);
}

@("toBe, but does")
unittest
{
    shouldFail(expect(4).not.toBe(4));
}

@("toBeOfType")
unittest
{
    interface I {}
    class A : I {}
    class B : I {}

    expect(new A()).not.toBeOfType!B;
}

@("toBeOfType, but is that exact type")
unittest
{
    interface I {}
    class A : I {}

    I a = new A();

    shouldFail(expect(a).not.toBeOfType!A);
}

@("toBeOfType, but is a sub-type")
unittest
{
    interface I {}
    class A : I {}

    A a = new A();

    shouldFail(expect(a).not.toBeOfType!I);
}

@("toBeOfType received null")
unittest
{
    Object o = null;
    expect(o).not.toBeOfType!Object;
}

@("toApproximatelyEqual")
unittest
{
    expect(4).not.toApproximatelyEqual(5.0);
}

@("toApproximatelyEqual, but does")
unittest
{
    shouldFail(expect(4).not.toApproximatelyEqual(4.0));
}

@("toApproximatelyEqual with custom maxRelDiff and maxAbsDiff")
unittest
{
    expect(10.0).not.toApproximatelyEqual(9.0, 0.05, 0.9);
}

@("toApproximatelyEqual, but does, with custom maxRelDiff and maxAbsDiff")
unittest
{
    shouldFail(
        expect(10.0).not.toApproximatelyEqual(9.2, 0.05, 0.9)
    );
}


@("toSatisfy")
unittest
{
    expect(4).not.toSatisfy(i => i == 5);
}

@("toSatisfy, but an exception is thrown")
unittest
{
    int delegate() dg = { throw new Exception("Oops"); };

    shouldFail(
        expect(dg).not.toSatisfy(predicate => predicate() == 5)
    );
}

@("toSatisfy, but does")
unittest
{
    shouldFail(expect(4).not.toSatisfy(i => i == 4));
}

@("toSatisfyAll")
unittest
{
    expect(4).not.toSatisfyAll(i => i == 4, i => i == 5);
}

@("toSatisfyAll, but does")
unittest
{
    shouldFail(expect(4).not.toSatisfyAll(i => i == 4, i => i <= 5));
}

@("toSatisfyAll, but an exception is thrown, despite otherwise succeeding")
unittest
{
    int delegate() dg = { throw new Exception("Oops"); };

    shouldFail(
        expect(dg).not.toSatisfyAll(
            p => false,
            p => p() <= 5
        )
    );
}

@("toSatisfyAny")
unittest
{
    expect(4).not.toSatisfyAny(i => i == 5, i => i == 3);
}

@("toSatisfyAny, but does")
unittest
{
    shouldFail(expect(4).not.toSatisfyAny(i => i == 5, i => i == 4));
}

@("toSatisfyAny, but an exception is thrown, despite otherwise succeeding")
unittest
{
    int delegate() dg = { throw new Exception("Oops"); };

    shouldFail(
        expect(dg).not.toSatisfyAny(
            p => false,
            p => p() <= 5
        )
    );
}

@("toThrow, since it throws the wrong thing")
unittest
{
    class CustomException : Exception
    {
        this(string message, string file = __FILE__, int line = __LINE__, Throwable nextInChain = null)
        {
            super(message, file, line, nextInChain);
        }
    }

    expect({ throw new Exception("test"); }).not.toThrow!CustomException;
}

@("toThrow, since it doesn't throw anything")
unittest
{
    expect({ return; }).not.toThrow!Exception;
}

@("toThrow, but throws the exact thing")
unittest
{
    shouldFail(
        expect({ throw new Exception("Test"); }).not.toThrow!Exception
    );
}

@("toThrow, but throws a sub-type")
unittest
{
    class CustomException : Exception
    {
        this(string message, string file = __FILE__, int line = __LINE__, Throwable nextInChain = null)
        {
            super(message, file, line, nextInChain);
        }
    }

    shouldFail(
        expect({ throw new CustomException("Test"); }).not.toThrow
    );
}

@("toMatch simple")
unittest
{
    expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`zzyzx.*berkshire`);
}

@("toMatch simple, but does")
unittest
{
    shouldFail(
        expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`berkshire.*zzyzx`)
    );
}

@("toMatch complex")
unittest
{
    expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`(?<=z{3}y)z(?=x)`);
}

@("toMatch complex, but does")
unittest
{
    shouldFail(
        expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`(?<=z{2}y)z(?=x)`)
    );
}

@("toMatch multiline")
unittest
{
    expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`berkshire.*\n.*zzyzx`, "ms");
}

@("toMatch multiline, but does")
unittest
{
    shouldFail(
        expect("botanical in berkshire,\nzoological in zzyzx").not.toMatch(`berkshire.*\n.*zzyzx`, "ms")
    );
}

@("toMatch case-insensitive")
unittest
{
    expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`ZZYZX`);
}

@("toMatch case-insensitive, but does")
unittest
{
    shouldFail(
        expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`ZZYZX`, "i")
    );
}

@("toMatch throws an InvalidExpectationException if the regex is invalid")
unittest
{
    shouldBeInvalid(
        expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`[a-z`)
    );
}

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

@("toContainOnly, (single element)")
unittest
{
    int[] arr = [1];
    expect(arr).not.toContainOnly(0);
}

@("toContainOnly, (single element) but does")
unittest
{
    int[] arr = [1];

    shouldFail(
        expect(arr).not.toContainOnly(1)
    );
}

@("toContainOnly, (multiple elements)")
unittest
{
    expect(repeat(999).take(20).array ~ [998]).not.toContainOnly(999);
}

@("toContainOnly, (multiple elements) but does")
unittest
{
    shouldFail(
        expect(repeat(999).take(20).array).not.toContainOnly(999)
    );
}

@("toContainOnly, (predicate)")
unittest
{
    expect(iota(0, 20, 2).array ~ [3]).not.toContainOnly((int e) => e % 2 == 0);
}

@("toContainOnly, (predicate) but does")
unittest
{
    shouldFail(
        expect([2, 4, 6, 8, 10]).not.toContainOnly((int e) => e % 2 == 0)
    );
}

@("Double negative should not be allowed")
unittest
{
    static assert(!__traits(compiles, expect(4).not.not));
}
