module exceeds_expectations.test.output_test;

import exceeds_expectations;
import exceeds_expectations.exceptions;
import std.conv : to;
import std.stdio;
import std.regex : matchFirst;


public void main(string[] args)
{
    string pattern = args.length >= 2 ? args[1] : ".*";

    // Basic
    if (!matchFirst("basic", pattern).empty)
    {
        callCatchPrint(expect(-20).toEqual(20));
        callCatchPrint(expect(long.max).not.toEqual(long.max));
    }

    // String equality
    if (!matchFirst("strings", pattern).empty)
    {
        callCatchPrint(expect("-20").toEqual("20"));
        callCatchPrint(expect("-2\n0").toEqual("2\n0"));
        callCatchPrint(expect("\n-20").toEqual("\n20"));
        callCatchPrint(expect("-20\n").toEqual("20\n"));
        callCatchPrint(expect("\n\n-\n2\n0\n\n").toEqual("20"));
        callCatchPrint(expect("20").toEqual("\n\n-\n2\n0\n\n"));
        callCatchPrint(expect("qwertyuiop\nasdfghjkl\nzxcvbnm").toEqual("qwertzuiop\nasdfghjkl\nyxcvbnm"));

        callCatchPrint(expect("-20").not.toEqual("-20"));
        callCatchPrint(expect("qwertyuiop\nasdfghjkl\nzxcvbnm").not.toEqual("qwertyuiop\nasdfghjkl\nzxcvbnm"));
    }

    // Struct equality
    if (!matchFirst("structs", pattern).empty)
    {
        import std.datetime : Date;

        struct S { int x; string y; }
        callCatchPrint(expect(S()).toEqual(S(5, "hello world")));
        callCatchPrint(expect(Date(2021, 5, 26)).toEqual(Date(1950, 12, 11)));
    }

    // Class equality
    if (!matchFirst("classes", pattern).empty)
    {
        class C { float x; float y; float z; this (float x, float y, float z) { this.x = x; this.y = y; this.z = z; } }
        callCatchPrint(expect(new C(float.nan, float.nan, float.nan)).toEqual(null));
        callCatchPrint(expect(null).toEqual(new C(float.nan, float.nan, float.nan)));
        callCatchPrint(expect(new C(1.0, 2.0, 3.0)).toEqual(new C(-16.666666667f, 8f/7f, -float.infinity)));
    }

    // Floating points
    if (!matchFirst("floats floating points approx equal", pattern).empty)
    {
        callCatchPrint(expect(3.0).toApproximatelyEqual(3.001));
        callCatchPrint(expect(3.0).toApproximatelyEqual(3.001, 0.00005, 0.000001));
    }

    // Satisfy predicates
    if (!matchFirst("satisfy predicates", pattern).empty)
    {
        callCatchPrint(expect("no").toSatisfy(e => e == "yes"));
        callCatchPrint(expect(-2).toSatisfyAny(n => n > 0, n => n % 2 == 1));
        callCatchPrint(expect(-2).toSatisfyAll(n => n > 0, n => n % 2 == 1));
        callCatchPrint(expect(-2).toSatisfyAll(n => n < 0, n => n % 2 == 1));
        callCatchPrint(expect(-2).toSatisfyAll(n => n > 0, n => n % 2 == 0));
    }

    // Identity
    if (!matchFirst("identity", pattern).empty)
    {
        struct S { int n; }
        class C {}

        callCatchPrint(expect(3 == 5).toBe(true));
        callCatchPrint(expect(S(5)).toBe(S(4)));
        callCatchPrint(expect("hello").toBe("world"));
        callCatchPrint(expect(new C()).toBe(new C()));
    }

    // Type
    if (!matchFirst("type toBeOfType", pattern).empty)
    {
        interface I1 {}
        interface I2 {}
        class C : I1 {}
        callCatchPrint(expect(new C()).toBeOfType!I2);
        callCatchPrint(expect(new C()).not.toBeOfType!I1);
    }

    // Throw
    if (!matchFirst("throws exceptions", pattern).empty)
    {
        callCatchPrint(expect({ return; }).toThrow);
        callCatchPrint(expect({ throw new Exception("test"); }).toThrow!Error);
        callCatchPrint(expect({ throw new Exception("test"); }).not.toThrow);
        callCatchPrint(expect({ throw new Exception("test"); }).not.toThrow!Exception);
    }

    // Match
    if (!matchFirst("regexp match", pattern).empty)
    {
        callCatchPrint(expect("zzyzx").toMatch(`[xyz]{6}`));
        callCatchPrint(expect("zzyzx\n8293498234").toMatch(`[xyz]{6}\n\d+`));
        callCatchPrint(expect("zzyzx").not.toMatch(`[xyz]{5}`));
        callCatchPrint(expect("zzyzx\n8293498234").not.toMatch(`x\n8`));
    }

    // Contain
    if (!matchFirst("contains", pattern).empty)
    {
        callCatchPrint(expect([1, 2, 3, 5, 3]).toContain(4));
        callCatchPrint(expect([1, 2, 3, 5, 3]).not.toContain(3));
        callCatchPrint(expect([1, 2, 3, 5, 3]).toContain([3, 4, 5]));
        callCatchPrint(expect([1, 2, 3, 5, 3]).not.toContain([3, 5, 3]));
        callCatchPrint(expect([1, 2, 3, 5, 3]).toContain((int e) => e < 0));
        callCatchPrint(expect([1, 2, 3, 5, 3]).not.toContain((int e) => e % 3 == 0));

        callCatchPrint(expect([4, 4, 4, 4, 5]).toContainOnly(4));
        callCatchPrint(expect([4, 4, 4, 4, 4]).not.toContainOnly(4));
        callCatchPrint(expect([1, 2, 3, 5, 3]).toContainOnly((int e) => e % 5 == 0));
        callCatchPrint(expect([1, 2, 3, 5, 3]).not.toContainOnly((int e) => e % 4 != 0));
    }

    // Contain
    if (!matchFirst("contains structs", pattern).empty)
    {
        import std.datetime : Date;

        struct S { int x; string y; }

        callCatchPrint(expect([S(1, "a"), S(2, "b")]).toContain(S(3, "c")));
        callCatchPrint(expect([S(1, "a"), S(2, "b")]).toContain([S(3, "c"), S(4, "d")]));
        callCatchPrint(expect([S(1, "a"), S(2, "b"), S(3, "c"), S(4, "d")]).not.toContain([S(2, "b"), S(3, "c")]));

        callCatchPrint(expect([Date(2021, 5, 29), Date(2021, 5, 30), Date(2021, 5, 31)]).toContain(Date(2021, 5, 1)));
        callCatchPrint(expect([Date(2021, 5, 29), Date(2021, 5, 30), Date(2021, 5, 31)]).not.toContain([Date(2021, 5, 30), Date(2021, 5, 31)]));
        callCatchPrint(expect([Date(2021, 5, 29), Date(2021, 5, 30), Date(2021, 5, 31)]).not.toContain(Date(2021, 5, 29)));
    }

    // Invalid
    if (!matchFirst("invalid", pattern).empty)
    {
        callCatchPrint(expect(2));
        callCatchPrint(expect(2).not);
        callCatchPrint(expect("zzyzx").toMatch(`[zyx`));
        callCatchPrint(expect("zzyzx").not.toMatch(`[zyx`));
        callCatchPrint(expect(3).toSatisfyAll());
        callCatchPrint(expect(3).not.toSatisfyAll());
        callCatchPrint(expect(3).toSatisfyAny());
        callCatchPrint(expect(3).not.toSatisfyAny());
    }
}

private void callCatchPrint(lazy void dg, string file = __FILE__, int line = __LINE__)
{
    try
    {
        dg();
        assert(false, "Test should have failed but didn't at " ~ file ~ ":" ~ line.to!string);
    }
    catch (FailingExpectationException e)
    {
        writeln("---------- BEGIN ----------");
        writeln(e.message);
        writeln("----------- END -----------");
    }
    catch (InvalidExpectationException e)
    {
        writeln("---------- BEGIN ----------");
        writeln(e.message);
        writeln("----------- END -----------");
    }
}