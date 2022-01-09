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
import std.typecons;


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
            throw new InvalidExpectationError(
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

        throw new FailingExpectationError(
            description,
            locationString,
            filePath, line
        );
    }


    /// Succeeds if `received != expected`. Throws a
    /// [FailingExpectationError] otherwise.
    public void toEqual(TExpected)(const auto ref TExpected expected)
    if (canCompareForEquality!(TReceived, TExpected))
    {
        completed = true;

        if (received != expected) return;

        fail(formatFailureMessage(
            "Forbidden", prettyPrint(expected),
            "Received", prettyPrint(received),
        ));
    }

    /// Succeeds if `predicate(received)` returns false. Throws a
    /// [FailingExpectationError] otherwise.
    ///
    /// Fails if an exception is thrown while evaluating the
    /// predicate.
    public void toSatisfy(bool delegate(const(TReceived)) predicate)
    {
        completed = true;

        try
        {
            immutable bool result = predicate(received);

            if (!result) return;

            fail(
                "Received: ".color(fg.red) ~ prettyPrint(received)
            );
        }
        catch (Throwable e)                             // @suppress(dscanner.suspicious.catch_em_all)
        {
            if (
                cast(FailingExpectationError) e ||
                cast(InvalidExpectationError) e
            )
            {
                throw e;
            }

            fail("Something was thrown while evaluating the predicate:\n" ~ prettyPrint(e));
        }
    }

    /// Succeeds if `predicate(received)` returns false for at least
    /// one of the given `predicates`. Throws a
    /// [FailingExpectationError] otherwise.
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
            throw new InvalidExpectationError(
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

        if (numPassed < predicates.length) return;

        fail(
            "Received: ".color(fg.red) ~ prettyPrint(received) ~ "\n" ~
            "Received value satisfied all predicates, but was expected to fail at least one."
        );
    }

    /// Succeeds if `predicate(received)` returns false for all
    /// `predicates`. Throws a [FailingExpectationError] otherwise.
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
            throw new InvalidExpectationError(
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

        if (numPassed == 0) return;

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
            "Received: ".color(fg.red) ~ prettyPrint(received) ~ "\n" ~
            description
        );
    }

    /// Succeeds if `received.isClose(expected, maxRelDiff,
    /// maxAbsDiff)` is false. Throws a [FailingExpectationError]
    /// otherwise.
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

        if (!received.isClose(expected, maxRelDiff, maxAbsDiff)) return;

        immutable real relDiff = fabs((received - expected) / expected);
        immutable real absDiff = fabs(received - expected);

        fail(formatFailureMessage(
            "Expected", prettyPrint(expected),
            "Received", prettyPrint(received),
            "Relative Difference", prettyPrintComparison(relDiff, maxRelDiff) ~ " (maxRelDiff)",
            "Absolute Difference", prettyPrintComparison(absDiff, maxAbsDiff) ~ " (maxAbsDiff)",
        ));
    }

    /// Succeeds if `received !is expected`. Throws a
    /// [FailingExpectationError] otherwise.
    ///
    /// This checks for *identity*, not *equality*. If `received !=
    /// expected` is desired, use [toEqual].
    public void toBe(TExpected)(const auto ref TExpected expected)
    {
        completed = true;

        if (received !is expected) return;

        fail(
            "Arguments reference the same object (received is expected == true)"
        );
    }

    /// If `received` has type [std.typecons.Nullable] or
    /// [std.typecons.NullableRef], then succeeds if
    /// `!received.isNull`. Otherwise, behaves exactly like
    /// `toBe(null)`.
    ///
    /// See_Also: [toBe]
    public void toBeNull()()
    if (
        is(TReceived : Nullable!Payload, Payload) ||
        is(TReceived : NullableRef!Payload, Payload)
    )
    {
        completed = true;

        if (!received.isNull) return;

        fail(
            "Received: ".color(fg.red) ~ prettyPrint(received)
        );
    }

    /// ditto
    public void toBeNull()()
    if (__traits(compiles, received is null))
    {
        toBe(null);
    }

    /// Succeeds if `received` is neither `TExpected` nor a sub-type
    /// of it. Throws a [FailingExpectationError] if `received` can be
    /// cast to `TExpected`.
    ///
    /// Note: `null` is considered not to be a sub-type of any class
    /// or interface, so if `null` is received, the expectation always
    /// succeeds.
    public void toBeOfType(TExpected)()
    if ((is(TExpected == class) || is(TExpected == interface)) &&
        (is(TReceived == class) || is(TReceived == interface)))
    {
        completed = true;

        if (!(cast(TExpected) received)) return;

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

    /// Calls `received` and catches any exceptions thrown by it.
    /// Succeeds if it doesn't catch `TExpected` or a sub-type. Throws
    /// a [FailingExpectationError] otherwise.
    ///
    /// There are three possible outcomes:
    ///
    /// - `received` throws a `TExpected` or one of its sub-types. A
    ///   [FailingExpectationError] is thrown.
    ///
    /// - `received` doesn't throw a `TExpected`, but does throw
    ///   something else. The expectation passes and the throwable
    ///   that was caught is ignored.
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

    /// Succeeds if `received` does not match the regular expression
    /// `pattern`. Throws a [FailingExpectationError] otherwise.
    public void toMatch(TExpected)(TExpected pattern, string flags = "")
    if (isSomeString!TReceived && isSomeString!TExpected)
    {
        completed = true;

        try
        {
            auto re = regex(pattern, flags);

            if (matchFirst(received, re).empty) return;

            string expectedString = prettyPrint(pattern);
            if (flags != "")
            {
                expectedString ~= " with flags " ~ prettyPrint(flags);
            }

            string highlightMatches(string input)
            {
                auto match = matchFirst(input, re);

                if (match.empty) return input;

                // Highlight line-by-line because the output looks buggy if the highlighting contains a line break
                return (
                    match.pre ~
                    match.hit.splitLines.map!(line => line.color(fg.black, bg.yellow)).join('\n') ~
                    highlightMatches(match.post)
                );
            }

            fail(formatFailureMessage(
                "Forbidden", expectedString,
                "Received", prettyPrint(highlightMatches(received)),
            ));
        }
        catch (RegexException e)
        {
            throw new InvalidExpectationError(
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

    /// Succeeds if `received` doesn't contain the fobidden element or
    /// sub-range, or if it doesn't contain any elements satisfying
    /// the given predicate.
    ///
    /// The predicate overload takes a function whose return type is
    /// `bool`, and whose single parameter is of a type that
    /// `received`'s elements can implicitly convert to.
    public void toContain(TExpected)(TExpected forbidden)
    if (__traits(compiles, received.countUntil(forbidden)))
    {
        completed = true;

        immutable ptrdiff_t index = received.countUntil(forbidden);

        if (index == -1) return;

        static if (is(ElementType!TExpected == ElementType!TReceived))
        {
            fail(formatFailureMessage(
                "Forbidden sub-range",
                prettyPrint(forbidden),

                "Received",
                prettyPrintHighlightedArray(received, [[index, index + forbidden.length]]),
            ));
        }
        else
        {
            fail(formatFailureMessage(
                "Forbidden element",
                prettyPrint(forbidden),

                "Received",
                prettyPrintHighlightedArray(received, [[index, index + 1]]),
            ));
        }
    }

    static if (isInputRange!TReceived && is(ElementType!TReceived))
    {
        /// ditto
        public void toContain(bool delegate(const(ElementType!TReceived)) predicate)
        {
            completed = true;

            if (!received.any!predicate) return;

            import std.stdio : writeln;

            size_t[] failingIndices;

            foreach (size_t index, const(ElementType!TReceived) element; received)
            {
                if (predicate(element))
                {
                    failingIndices ~= index;
                }
            }

            size_t[2][] failingRanges = failingIndices.map!(e => cast(size_t[2])[e, e + 1]).array;

            fail(
                "Received: ".color(fg.red) ~ prettyPrintHighlightedArray(received, failingRanges) ~ "\n" ~
                "Some elements satisfy the predicate."
            );
        }
    }


    /// Succeeds if there is at least one elemt in `received` not
    /// equal to expected, or if at least one element in `received`
    /// doesn't satisfy `predicate`.
    ///
    /// The predicate overload takes a function whose return type is
    /// `bool`, and whose single parameter is of a type that
    /// `received`'s elements can implicitly convert to.
    public void toContainOnly(TExpected)(TExpected expected)
    if (
        __traits(compiles, rvalueOf!(ElementType!TReceived) == expected)
    )
    {
        completed = true;

        if (!all!(e => e == expected)(received)) return;

        fail(formatFailureMessage(
            "Forbidden", prettyPrint(expected),
            "Received", prettyPrint(received),
            "The received range contains only the forbidden value."
        ));
    }


    static if (isInputRange!TReceived && is(ElementType!TReceived))
    {
        /// ditto
        public void toContainOnly(bool delegate(const(ElementType!TReceived)) predicate)
        {
            completed = true;

            if (!received.all!predicate) return;

            fail(
                "Received: ".color(fg.red) ~ prettyPrint(received) ~ "\n" ~
                "All elements in the received array satisfy the predicate."
            );
        }
    }
}
