module exceeds_expectations.expectation;

import colorize;
import exceeds_expectations.exceptions;
import exceeds_expectations.expect_not;
import exceeds_expectations.utils;
import std.algorithm;
import std.conv;
import std.file;
import std.math;
import std.range;
import std.traits;


/**
 *	Initiates the expectation chain.
 *
 *  TODO: Try to make this auto-ref
 */
public Expectation!T expect(T)(const T received, string filePath = __FILE__, size_t line = __LINE__)
{
    return Expectation!T(received, filePath, line);
}


/**
 *  Wraps any object and allows expectations to be made.
 */
public struct Expectation(TReceived)
{
    private const(TReceived) received;
    private immutable string filePath;
    private immutable size_t line;
    private bool completed = false;

    private this(const(TReceived) received, string filePath, size_t line)
    {
        this.received = received;
        this.filePath = filePath;
        this.line = line;
    }

    ~this()
    {
        if (!completed)
        {
            throw new FailingExpectationException(
                "`expect` was called but no assertion was made at " ~
                filePath ~ "(" ~ line.to!string ~ "): \n\n" ~
                formatCode(readText(filePath), line, 2) ~ "\n",
                filePath, line
            );
        }
    }

    private void fail(string differences, string description = "")
    {
        string locationString = "Failing expectation at " ~ filePath ~ "(" ~ line.to!string ~ ")";

        throw new FailingExpectationException(
            description,
            locationString,
            differences,
            filePath, line
        );
    }

    /// Negates the expectation
    public ExpectNot!TReceived not()
    {
        completed = true; // Because a new expectation is returned, and this one will be discarded.
        return ExpectNot!TReceived(received, filePath, line);
    }

    /// Throws a [FailingExpectationException] unless `received == expected`.
    public void toEqual(TExpected)(const auto ref TExpected expected)
    if (canCompareForEquality!(TReceived, TExpected))
    {
        completed = true;

        if (received != expected)
        {
            fail(
                formatDifferences(stringify(expected), stringify(received))
            );
        }
    }

    /// Throws a [FailingExpectationException] unless `predicate(received)` returns true.
    public void toSatisfy(bool delegate(const(TReceived)) predicate)
    {
        completed = true;

        if (!predicate(received))
        {
            fail(
                "Received: " ~ stringify(received).color(fg.light_red)
            );
        }
    }

    /// Throws a [FailingExpectationException] unless `predicate(received)` returns true for all `predicates`.
    public void toSatisfyAll(bool delegate(const(TReceived))[] predicates...)
    {
        completed = true;

        if (predicates.length == 0)
        {
            throw new FailingExpectationException(
                "Missing predicates at " ~ filePath ~ "(" ~ line.to!string ~ "): \n" ~
                "\n" ~ formatCode(readText(filePath), line, 2) ~ "\n",
                filePath, line
            );
        }

        if (predicates.length == 1)
        {
            toSatisfy(predicates[0]);
            return;
        }


        auto results = predicates.map!(p => p(received));
        immutable size_t numFailures = count!(e => !e)(results);

        if(numFailures > 0)
        {
            size_t[] failingIndices =
                results
                .zip(iota(0, results.length))
                .filter!(tup => !tup[0])
                .map!(tup => tup[1])
                .array;

            immutable string description =
                numFailures == predicates.length ?
                "Received value does not satisfy any predicates." :
                (
                    "Received value does not satisfy " ~
                    (
                        (
                            numFailures == 1 ?
                            "predicate at index " :
                            "predicates at indices "
                        ) ~ stringifyArray(failingIndices) ~ " (first argument is index 0)."
                    )
                );

            fail(
                "Received: " ~ stringify(received).color(fg.light_red),
                description
            );
        }
    }

    /// Throws a [FailingExpectationException] if `predicate(received)` returns false for all `predicates`.
    public void toSatisfyAny(bool delegate(const(TReceived))[] predicates...)
    {
        completed = true;

        if (predicates.length == 0)
        {
            throw new FailingExpectationException(
                "Missing predicates at " ~ filePath ~ "(" ~ line.to!string ~ "): \n" ~
                "\n" ~ formatCode(readText(filePath), line, 2) ~ "\n",
                filePath, line
            );
        }

        if (predicates.length == 1)
        {
            toSatisfy(predicates[0]);
            return;
        }

        auto results = predicates.map!(p => p(received));
        immutable size_t numPassed = count!(e => e)(results);

        if(numPassed == 0)
        {
            fail(
                "Received: " ~ stringify(received).color(fg.light_red)
            );
        }
    }

    /**
     * Throws a [FailingExpectationException] unless `received.isClose(expected, maxRelDiff, maxAbsDiff)`.
     *
     * `maxRelDiff` and `maxAbsDiff` have the same default values as in [std.math.isClose].
     *
     * See_Also: std.math.isClose
     */
    public void toApproximatelyEqual(TExpected, F : real)(
        const auto ref TExpected expected,
        F maxRelDiff = CommonDefaultFor!(TReceived, TExpected),
        F maxAbsDiff = 0.0
    )
    if (
        __traits(compiles, received.isClose(expected, maxRelDiff, maxAbsDiff))
    )
    {
        completed = true;

        if (!received.isClose(expected, maxRelDiff, maxAbsDiff))
        {
            fail(
                formatApproxDifferences(received, expected, maxRelDiff, maxAbsDiff)
            );
        }
    }

    /// Throws a [FailingExpectationException] unless `received is expected`.
    public void toBe(TExpected)(const auto ref TExpected expected)
    {
        completed = true;

        if (received !is expected)
        {
            fail(
                "",
                "Arguments do not reference the same object (received !is expected)."
            );
        }
    }

    /// Throws a [FailingExpectationException] unless `received` is a sub-type of `TExpected`.
    public void toBeOfType(TExpected)()
    if ((is(TExpected == class) || is(TExpected == interface)) &&
        (is(TReceived == class) || is(TReceived == interface)))
    {
        completed = true;

        if (!cast(TExpected) received)
        {
            fail(
                formatDifferences(
                    "`" ~ typeid(TExpected).to!string ~ "`",
                    "`" ~ received.to!string ~ "`"
                ),
                "Received value does not extend the expected type."
            );
        }
    }

    /// If `received` throws a `TExpected` (or one of its sub-types),
    /// it is caught and this function exits successfully.
    /// If `received` does not throw a `TExpected`, but does throw
    /// something else, a FailingExpectationException is thrown.
    /// If `received` doesn't throw anything, a
    /// FailingExpectationException is thrown.
    public void toThrow(TExpected : Throwable = Throwable)()
    if (isCallable!TReceived)
    {
        completed = true;

        try
        {
            received();
        }
        catch (Throwable e)             // @suppress(dscanner.suspicious.catch_em_all)
        {
            if (cast(TExpected) e) return;

            fail(
                formatDifferences(
                    typeid(TExpected).name,
                    typeid(e).name
                )
            );
        }

        fail(
            formatDifferences(
                typeid(TExpected).name,
                "Nothing was thrown"
            )
        );
    }
}
