module exceeds_expectations.expect;

import colorize;
import exceeds_expectations.exceptions;
import exceeds_expectations.expect_not;
import exceeds_expectations.pretty_print;
import exceeds_expectations.utils;
import std.algorithm;
import std.conv;
import std.file;
import std.math;
import std.range;
import std.traits;


/**
 * Begins an expectation.
 */
public Expect!T expect(T)(const T received, string filePath = __FILE__, size_t line = __LINE__)
{
    // TODO: Try to make this function auto-ref
    return Expect!T(received, filePath, line);
}


/**
 * Wrapper whose methods are expectations.
 */
public struct Expect(TReceived)
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

    /// Negates the expectation. Returns an [ExpectNot].
    public ExpectNot!TReceived not()
    {
        completed = true; // Because a new expectation is returned, and this one will be discarded.
        return ExpectNot!TReceived(received, filePath, line);
    }

    /// Checks that `received == expected` and throws
    /// [FailingExpectationException] otherwise.
    public void toEqual(TExpected)(const auto ref TExpected expected)
    if (canCompareForEquality!(TReceived, TExpected))
    {
        completed = true;

        if (received != expected)
        {
            fail(
                formatDifferences(prettyPrint(expected), prettyPrint(received), false)
            );
        }
    }

    /// Checks that `predicate(received)` returns true and throws a
    /// [FailingExpectationException] otherwise.
    public void toSatisfy(bool delegate(const(TReceived)) predicate)
    {
        completed = true;

        if (!predicate(received))
        {
            fail(
                "Received: ".color(fg.light_red) ~ prettyPrint(received)
            );
        }
    }

    /// Checks that `predicate(received)` returns true for all `predicates` and
    /// throws a [FailingExpectationException] otherwise.
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
                "Received value did not satisfy any predicates, but was expected to satisfy all." :
                (
                    "Received value did not satisfy " ~
                    (
                        (
                            numFailures == 1 ?
                            "predicate at index " :
                            "predicates at indices "
                        ) ~ humanReadableNumbers(failingIndices) ~ ", but was expected to satisfy all."
                    )
                );

            fail(
                "Received: ".color(fg.light_red) ~ prettyPrint(received) ~ "\n" ~
                description
            );
        }
    }

    /// Checks that `predicate(received)` returns true for at least one of the
    /// given `predicates` and throws a [FailingExpectationException] otherwise.
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

        if(numPassed == 0)
        {
            fail(
                "Received: ".color(fg.light_red) ~ prettyPrint(received) ~ "\n" ~
                "Received value did not satisfy any predicates, but was expected to satisfy at least one."
            );
        }
    }

    /**
     * Checks that `received.isClose(expected, maxRelDiff, maxAbsDiff)` and
     * throws a [FailingExpectationException] otherwise.
     *
     * `maxRelDiff` and `maxAbsDiff` have the same default values as in
     * [std.math.isClose].
     *
     * See_Also: [std.math.isClose]
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
                formatDifferences(prettyPrint(expected), prettyPrint(received), false) ~
                formatApproxDifferences(expected, received, maxRelDiff, maxAbsDiff)
            );
        }
    }

    /// Checks that `received is expected` and throws a
    /// [FailingExpectationException] otherwise.
    public void toBe(TExpected)(const auto ref TExpected expected)
    {
        completed = true;

        if (received !is expected)
        {
            fail(
                "Arguments do not reference the same object (received is expected == false)."
            );
        }
    }

    /// Checks that received is a `TExpected` or a sub-type of it. Throws a
    /// [FailingExpectationException] if `received` cannot be cast to
    /// `TExpected` or if `received is null`.
    public void toBeOfType(TExpected)()
    if ((is(TExpected == class) || is(TExpected == interface)) &&
        (is(TReceived == class) || is(TReceived == interface)))
    {
        completed = true;

        if (received is null)
        {
            fail(
                formatDifferences(
                    prettyPrint(typeid(TExpected)),
                    "null",
                    false
                )
            );
        }

        if (!cast(TExpected) received)
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
                    false,
                )
            );
        }
    }

    /**
     * Calls `received` and catches any exceptions thrown by it. There are three
     * possible outcomes:
     *
     * - `received` throws a `TExpected` or one of its sub-types. The
     *   expectation passes.
     *
     * - `received` doesn't throw a `TExpected`, but does throw something else.
     *   A [FailingExpectationException] is thrown.
     *
     * - `received` doesn't throw anything. A [FailingExpectationException] is
     *   thrown.
     */
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
                formatTypeDifferences(
                    typeid(TExpected),
                    typeid(e),
                    false
                )
            );
        }

        fail(
            formatDifferences(
                prettyPrint(typeid(TExpected)),
                "Nothing was thrown",
                false
            )
        );
    }
}
