module exceeds_expectations.expect_not;

import colorize;
import exceeds_expectations.exceptions;
import exceeds_expectations.pretty_print;
import exceeds_expectations.utils;
import std.algorithm;
import std.conv;
import std.file;
import std.math;
import std.range;
import std.traits;


/**
 * Provides negated versions of the usual expectations in [Expect].
 */
struct ExpectNot(TReceived)
{
    private const(TReceived) received;
    private immutable string filePath;
    private immutable size_t line;
    private bool completed = false;

    package this(const(TReceived) received, string filePath, size_t line)
    {
        this.received = received;
        this.filePath = filePath;
        this.line = line;
    }

    ~this()
    {
        if (!completed)
        {
            throw new InvalidExpectationException(
                "`expect` was called but no assertion was made at " ~
                filePath ~ "(" ~ line.to!string ~ "): \n\n" ~
                formatCode(readText(filePath), line, 2) ~ "\n",
                filePath, line
            );
        }
    }


    private void fail(string description)
    {
        string locationString = "Failing expectation at " ~ filePath ~ "(" ~ line.to!string ~ ")";

        throw new FailingExpectationException(
            description,
            locationString,
            filePath, line
        );
    }


    /// Throws a [FailingExpectationException] unless `received != expected`.
    public void toEqual(TExpected)(const auto ref TExpected expected)
    if (canCompareForEquality!(TReceived, TExpected))
    {
        completed = true;

        if (received == expected)
        {
            fail(
                formatDifferences(prettyPrint(expected), prettyPrint(received), true)
            );
        }
    }

    /// Throws a [FailingExpectationException] if `predicate(received)` returns true.
    public void toSatisfy(bool delegate(const(TReceived)) predicate)
    {
        completed = true;

        if (predicate(received))
        {
            fail(
                "Received: ".color(fg.light_red) ~ prettyPrint(received)
            );
        }
    }

    /// Throws a [FailingExpectationException] if `predicate(received)` returns true for all given predicates.
    public void toSatisfyAll(bool delegate(const(TReceived))[] predicates...)
    {
        completed = true;

        if (predicates.length == 0)
        {
            throw new InvalidExpectationException(
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

        if (numPassed >= predicates.length)
        {
            fail(
                "Received: ".color(fg.light_red) ~ prettyPrint(received) ~ "\n" ~
                "Received value satisfies all predicates."
            );
        }
    }

    /// Throws a [FailingExpectationException] if `predicate(received)` returns false for any given predicate.
    public void toSatisfyAny(bool delegate(const(TReceived))[] predicates...)
    {
        completed = true;

        if (predicates.length == 0)
        {
            throw new InvalidExpectationException(
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

        if (numPassed > 0)
        {
            size_t[] passingIndices =
                results
                .zip(iota(0, results.length))
                .filter!(tup => tup[0])
                .map!(tup => tup[1])
                .array;

            immutable string description =
                numPassed == predicates.length ?
                "Received value satisfies all predicates." :
                (
                    "Received value satisfies " ~
                    (
                        (
                            numPassed == 1 ?
                            "predicate at index " :
                            "predicates at indices "
                        ) ~ humanReadableNumbers(passingIndices) ~ "."
                    )
                );

            fail(
                "Received: ".color(fg.light_red) ~ prettyPrint(received) ~ "\n" ~
                description
            );
        }

    }

    /**
     * Throws a [FailingExpectationException] if `received.isClose(expected, maxRelDiff, maxAbsDiff)`.
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

        if (received.isClose(expected, maxRelDiff, maxAbsDiff))
        {
            fail(
                formatDifferences(prettyPrint(expected), prettyPrint(received), true) ~
                formatApproxDifferences(expected, received, maxRelDiff, maxAbsDiff)
            );
        }
    }

    /// Throws a [FailingExpectationException] if `received is expected`.
    public void toBe(TExpected)(const auto ref TExpected expected)
    {
        completed = true;

        if (received is expected)
        {
            fail(
                "Arguments reference the same object (received is expected == true)"
            );
        }
    }

    /// Throws a [FailingExpectationException] if `received` is a sub-type of `TExpected`.
    /// Will never throw if `received` is null.
    public void toBeOfType(TExpected)()
    if ((is(TExpected == class) || is(TExpected == interface)) &&
        (is(TReceived == class) || is(TReceived == interface)))
    {
        completed = true;

        if (cast(TExpected) received)
        {
            TypeInfo receivedTypeInfo = typeid(received);

            static if (is(TReceived == interface))
            {
                receivedTypeInfo = typeid(cast(Object) received);
            }

            fail(
                formatTypeDifferences(
                    typeid(TExpected),
                    receivedTypeInfo,
                    true
                )
            );
        }
    }

    /// If `received` throws a `TExpected` (or one of its sub-types),
    /// a [FailingExpectationException] is thrown.
    /// If `received` does not throw a `TExpected`, but does throw
    /// something else, the function exits successfully.
    /// If `received` doesn't throw anything, the function exits successfully.
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
            if (!(cast(TExpected) e)) return;

            fail(
                formatTypeDifferences(
                    typeid(TExpected),
                    typeid(e),
                    true
                )
            );
        }
    }
}
