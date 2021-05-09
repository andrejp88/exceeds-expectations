module exceeds_expectations.test.not;

import exceeds_expectations;
import exceeds_expectations.exceptions;
import exceeds_expectations.test;


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
    expect("botanical in berkshire, zoological in zyzzx").not.toMatch(`zyzzx.*berkshire`);
}

@("toMatch simple, but does")
unittest
{
    shouldFail(
        expect("botanical in berkshire, zoological in zyzzx").not.toMatch(`berkshire.*zyzzx`)
    );
}

@("toMatch complex")
unittest
{
    expect("botanical in berkshire, zoological in zyzzx").not.toMatch(`(?<=zy)z{3}(?=x)`);
}

@("toMatch complex, but does")
unittest
{
    shouldFail(
        expect("botanical in berkshire, zoological in zyzzx").not.toMatch(`(?<=zy)z{2}(?=x)`)
    );
}

@("toMatch multiline")
unittest
{
    expect("botanical in berkshire, zoological in zyzzx").not.toMatch(`berkshire.*\n.*zyzzx`, "ms");
}

@("toMatch multiline, but does")
unittest
{
    shouldFail(
        expect("botanical in berkshire,\nzoological in zyzzx").not.toMatch(`berkshire.*\n.*zyzzx`, "ms")
    );
}

@("toMatch case-insensitive")
unittest
{
    expect("botanical in berkshire, zoological in zyzzx").not.toMatch(`ZYZZX`);
}

@("toMatch case-insensitive, but does")
unittest
{
    shouldFail(
        expect("botanical in berkshire, zoological in zyzzx").not.toMatch(`ZYZZX`, "i")
    );
}

@("toMatch throws an InvalidExpectationException if the regex is invalid")
unittest
{
    try
    {
        expect("botanical in berkshire, zoological in zyzzx").not.toMatch(`[a-z`);
    }
    catch (InvalidExpectationException e)
    {
        debug (SHOW_MESSAGES)
        {
            import std.stdio : writeln;
            writeln(e.message);
        }
        return;
    }

    assert(false, "Expected to catch an InvalidExpectationException but didn't.");
}

@("Double negative should not be allowed")
unittest
{
    static assert(!__traits(compiles, expect(4).not.not));
}
