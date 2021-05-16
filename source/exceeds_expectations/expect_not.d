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
import std.regex;
import std.string;
import std.traits;


/// Provides negated versions of the usual expectations in [Expect].
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


    /// Checks that `received != expected` and throws a
    /// [FailingExpectationException] otherwise.
    public void toEqual(TExpected)(const auto ref TExpected expected)
    if (canCompareForEquality!(TReceived, TExpected))
    {
        completed = true;

        if (received == expected)
        {
            fail(formatFailureMessage(
                "Forbidden", prettyPrint(expected),
                "Received", prettyPrint(received),
            ));
        }
    }

    /// Checks that `predicate(received)` returns false and throws a
    /// [FailingExpectationException] otherwise.
    ///
    /// Fails if an exception is thrown while evaluating the
    /// predicate.
    public void toSatisfy(bool delegate(const(TReceived)) predicate)
    {
        completed = true;

        try
        {
            immutable bool result = predicate(received);

            if (result)
            {
                fail(
                    "Received: ".color(fg.light_red) ~ prettyPrint(received)
                );
            }
        }
        catch (Throwable e)                             // @suppress(dscanner.suspicious.catch_em_all)
        {
            if (
                cast(FailingExpectationException) e ||
                cast(InvalidExpectationException) e
            )
            {
                throw e;
            }

            fail("Something was thrown while evaluating the predicate:\n" ~ prettyPrint(e));
        }
    }

    /// Checks that `predicate(received)` returns false for at least
    /// one of the given `predicates` and throws a
    /// [FailingExpectationException] otherwise.
    ///
    /// All predicates are evaluated.
    ///
    /// Fails if something is thrown while evaluating any of the
    /// predicates, even if another predicate returns false.
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


        auto results =
            predicates
            .zip(iota(0, predicates.length))
            .map!((predicateIndexPair) {
                bool delegate(const(TReceived)) predicate = predicateIndexPair[0];
                size_t index = predicateIndexPair[1];
                try
                {
                    return predicate(received);
                }
                catch (Throwable e)                             // @suppress(dscanner.suspicious.catch_em_all)
                {
                    fail(
                        "Something was thrown while evaluating predicate at index " ~ index.to!string ~ ":\n" ~
                        prettyPrint(e)
                    );
                    return false;
                }
            });

        immutable size_t numPassed = count!(e => e)(results);

        if (numPassed >= predicates.length)
        {
            fail(
                "Received: ".color(fg.light_red) ~ prettyPrint(received) ~ "\n" ~
                "Received value satisfied all predicates, but was expected to fail at least one."
            );
        }
    }

    /// Checks that `predicate(received)` returns false for all
    /// `predicates` and throws a [FailingExpectationException]
    /// otherwise.
    ///
    /// All predicates are evaluated.
    ///
    /// Fails if something is thrown while evaluating any of the
    /// predicates, even if none of the predicates return true.
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

        auto results =
            predicates
            .zip(iota(0, predicates.length))
            .map!((predicateIndexPair) {
                bool delegate(const(TReceived)) predicate = predicateIndexPair[0];
                size_t index = predicateIndexPair[1];
                try
                {
                    return predicate(received);
                }
                catch (Throwable e)                             // @suppress(dscanner.suspicious.catch_em_all)
                {
                    fail(
                        "Something was thrown while evaluating predicate at index " ~ index.to!string ~ ":\n" ~
                        prettyPrint(e)
                    );
                    return false;
                }
            });

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
                "Received value satisfied all predicates" :
                (
                    "Received value satisfied " ~
                    (
                        (
                            numPassed == 1 ?
                            "predicate at index " :
                            "predicates at indices "
                        ) ~ humanReadableNumbers(passingIndices)
                    )
                ) ~ ", but was expected not to satisfy any.";

            fail(
                "Received: ".color(fg.light_red) ~ prettyPrint(received) ~ "\n" ~
                description
            );
        }

    }

    /// Checks that `received.isClose(expected, maxRelDiff,
    /// maxAbsDiff)` and throws a [FailingExpectationException] if it
    /// is.
    ///
    /// `maxRelDiff` and `maxAbsDiff` have the same default values as
    /// in [std.math.isClose].
    ///
    /// See_Also: [std.math.isClose]
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

    /// Checks that `received !is expected` and throws a
    /// [FailingExpectationException] otherwise.
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

    /// Checks that received is not a `TExpected` nor a sub-type of
    /// it. Throws a [FailingExpectationException] if `received` can
    /// be cast to `TExpected`.
    ///
    /// Note: `null` is considered not to be a sub-type of any class
    /// or interface.
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

    /// Calls `received` and catches any exceptions thrown by it. If
    /// it catches `TExpected` or a sub-type, the expectation fails.
    ///
    /// There are three possible outcomes:
    ///
    /// - `received` throws a `TExpected` or one of its sub-types. A
    ///   [FailingExpectationException] is thrown.
    ///
    /// - `received` doesn't throw a `TExpected`, but does throw
    ///   something else. The expectation passes.
    ///
    /// - `received` doesn't throw anything. The expectation passes.
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
                ) ~
                "Details:".color(fg.yellow) ~ "\n" ~
                prettyPrint(e)
            );
        }
    }

    /// Fails if `received` matches the regular expression `pattern`.
    public void toMatch(TExpected)(TExpected pattern, string flags = "")
    if (isSomeString!TReceived && isSomeString!TExpected)
    {
        completed = true;

        try
        {
            auto re = regex(pattern, flags);
            auto matchResult = matchFirst(received, re);

            if (!matchResult.empty)
            {
                string expectedString = prettyPrint(pattern);
                if (flags != "")
                {
                    expectedString ~= " with flags " ~ prettyPrint(flags);
                }

                // Highlight line-by-line because the output looks buggy if the highlighting contains a line break
                string highlightedReceived = (
                    matchResult.pre ~
                    matchResult.hit.splitLines.map!(line => line.color(bg.yellow)).join('\n') ~
                    matchResult.post
                );

                fail(formatFailureMessage(
                    "Forbidden", expectedString,
                    "Received", prettyPrint(highlightedReceived),
                ));
            }
        }
        catch (RegexException e)
        {
            throw new InvalidExpectationException(
                "toMatch received an invalid regular expression pattern at " ~
                filePath ~ "(" ~ line.to!string ~ "): \n\n" ~
                formatCode(readText(filePath), line, 2) ~ "\n" ~
                "Details:".color(fg.yellow) ~ "\n" ~ prettyPrint(e),
                filePath,
                line,
                e
            );
        }
    }

    /// Fails if `received` contains the expected element or sub-range.
    public void toContain(TExpected)(TExpected expected)
    if (__traits(compiles, received.countUntil(expected)))
    {
        completed = true;

        immutable ptrdiff_t index = received.countUntil(expected);

        if (index != -1)
        {
            static if (is(ElementType!TExpected == ElementType!TReceived))
            {
                fail(
                    "Forbidden sub-range: ".color(fg.green) ~
                    prettyPrint(expected) ~ "\n" ~

                    "Received:            ".color(fg.red) ~
                    prettyPrintHighlightedArray(received, [[index, index + expected.length]]) ~ "\n",
                );
            }
            else
            {
                fail(
                    "Forbidden element: ".color(fg.green) ~
                    prettyPrint(expected) ~ "\n" ~

                    "Received:          ".color(fg.red) ~
                    prettyPrintHighlightedArray(received, [[index, index + 1]]) ~ "\n",
                );
            }
        }
    }
}
