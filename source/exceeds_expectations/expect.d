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
import std.regex;
import std.traits;
import std.typecons;


/// Begins an expectation.
public Expect!T expect(T)(T received, string filePath = __FILE__, size_t line = __LINE__)
{
    // TODO: Try to make this function auto-ref
    return Expect!T(received, filePath, line);
}


/// Runs expectations on a given value. Instances must be created
/// using [expect].
public struct Expect(TReceived)
{
    private TReceived received;
    private immutable string filePath;
    private immutable size_t line;
    private bool completed = false;

    private this(TReceived received, string filePath, size_t line)
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

    /// Negates the expectation.
    public ExpectNot!TReceived not()
    {
        completed = true; // Because a new expectation is returned, and this one will be discarded.
        return ExpectNot!TReceived(received, filePath, line);
    }

    /// Succeeds if `received == expected`. Throws a
    /// [FailingExpectationError] otherwise.
    public void toEqual(TExpected)(const auto ref TExpected expected)
    if (canCompareForEquality!(TReceived, TExpected))
    {
        completed = true;

        if (received == expected) return;

        fail(
            formatFailureMessage(
                "Expected", prettyPrint(expected),
                "Received", prettyPrint(received),
            )
        );
    }

    /// Succeeds if `predicate(received)` returns true. Throws a
    /// [FailingExpectationError] otherwise.
    public void toSatisfy(bool delegate(const(TReceived)) predicate)
    {
        completed = true;

        try
        {
            if (predicate(received)) return;

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

    /// Succeeds if `predicate(received)` returns true for all
    /// `predicates`. Throws a [FailingExpectationError] otherwise.
    ///
    /// All predicates are evaluated.
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

        immutable size_t numFailures = count!(e => !e)(results);

        if (numFailures == 0) return;

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
            "Received: ".color(fg.red) ~ prettyPrint(received) ~ "\n" ~
            description
        );
    }

    /// Succeeds if `predicate(received)` returns true for at least
    /// one of the given `predicates`. Throws a
    /// [FailingExpectationError] otherwise.
    ///
    /// All predicates are evaluated.
    ///
    /// If any predicate throws, the expectation will fail, even if
    /// other predicates returned true.
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

        if (numPassed > 0) return;

        fail(
            "Received: ".color(fg.red) ~ prettyPrint(received) ~ "\n" ~
            "Received value did not satisfy any predicates, but was expected to satisfy at least one."
        );
    }

    /// Succeeds if `received.isClose(expected, maxRelDiff,
    /// maxAbsDiff)`. Throws a [FailingExpectationError] otherwise.
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

        if (received.isClose(expected, maxRelDiff, maxAbsDiff)) return;

        immutable real relDiff = fabs((received - expected) / expected);
        immutable real absDiff = fabs(received - expected);

        fail(formatFailureMessage(
            "Expected", prettyPrint(expected),
            "Received", prettyPrint(received),
            "Relative Difference", prettyPrintComparison(relDiff, maxRelDiff) ~ " (maxRelDiff)",
            "Absolute Difference", prettyPrintComparison(absDiff, maxAbsDiff) ~ " (maxAbsDiff)",
        ));
    }

    /// Succeeds if `received is expected`. Throws a
    /// [FailingExpectationError] otherwise.
    ///
    /// This checks for *identity*, not *equality*. If `received ==
    /// expected` is desired, use [toEqual].
    public void toBe(TExpected)(const auto ref TExpected expected)
    {
        completed = true;

        if (received is expected) return;

        if (hasIndirections!TExpected || hasIndirections!TReceived)
        {
            fail(
                "Arguments do not reference the same object ((received is expected) == false)."
            );
        }
        else
        {
            fail(formatFailureMessage(
                "Expected", prettyPrint(expected),
                "Received", prettyPrint(received),
            ));
        }
    }

    /// If `received` has type [std.typecons.Nullable] or
    /// [std.typecons.NullableRef], then succeeds if
    /// `received.isNull`. Otherwise, behaves exactly like
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

        if (received.isNull) return;

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

    /// Succeeds if `received` is a `TExpected` or a sub-type of it.
    /// Throws a [FailingExpectationError] if `received` cannot be
    /// cast to `TExpected` or if `received is null`.
    ///
    /// Note: `null` is considered not to be a sub-type of any class
    /// or interface, so if `null` is received, the expectation always
    /// fails.
    public void toBeOfType(TExpected)()
    if ((is(TExpected == class) || is(TExpected == interface)) &&
        (is(TReceived == class) || is(TReceived == interface)))
    {
        completed = true;

        if (received is null)
        {
            fail(
                formatFailureMessage(
                    "Expected", prettyPrint(typeid(TExpected)),
                    "Received", "null"
                )
            );
        }

        if (cast(TExpected) received) return;

        static if (is(TReceived == interface))
        {
            TypeInfo receivedTypeInfo = typeid(cast(Object) received);
        }
        else
        {
            TypeInfo receivedTypeInfo = typeid(received);
        }

        fail(
            formatTypeDifferences(
                typeid(TExpected),
                receivedTypeInfo,
                false,
            )
        );
    }

    /// Calls `received` and catches any exceptions thrown by it.
    /// Succeeds if it catches `TExpected` or a sub-type. Throws a
    /// [FailingExpectationError] otherwise.
    ///
    /// There are three possible outcomes:
    ///
    /// - `received` throws a `TExpected` or one of its sub-types. The
    ///   expectation passes.
    ///
    /// - `received` doesn't throw a `TExpected`, but does throw
    ///   something else. A [FailingExpectationError] is thrown.
    ///
    /// - `received` doesn't throw anything. A
    ///   [FailingExpectationError] is thrown.
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
                ) ~
                "Details:".color(fg.yellow) ~ "\n" ~
                prettyPrint(e)
            );
        }

        fail(
            formatFailureMessage(
                "Expected", prettyPrint(typeid(TExpected)),
                "Received", "Nothing was thrown"
            )
        );
    }


    /// Succeeds if `received` matches the regular expression
    /// `pattern`. Throws a [FailingExpectationError] otherwise.
    public void toMatch(TExpected)(TExpected pattern, string flags = "")
    if (isSomeString!TReceived && isSomeString!TExpected)
    {
        completed = true;

        try
        {
            auto re = regex(pattern, flags);

            if (!matchFirst(received, re).empty) return;

            string expectedString = prettyPrint(pattern);
            if (flags != "")
            {
                expectedString ~= " with flags " ~ prettyPrint(flags);
            }

            fail(
                formatFailureMessage(
                    "Expected", prettyPrint(pattern),
                    "Received", prettyPrint(received),
                )
            );
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

    /// Succeeds if `received` contains the `expected` element or
    /// sub-range, or at least one element satisfying the given
    /// predicate.
    ///
    /// The predicate overload takes a function whose return type is
    /// `bool`, and whose single parameter is of a type that
    /// `received`'s elements can implicitly convert to.
    public void toContain(TExpected)(TExpected expected)
    if (__traits(compiles, received.canFind(expected)))
    {
        completed = true;

        if (received.canFind(expected)) return;

        static if (is(ElementType!TExpected == ElementType!TReceived))
        {
            fail(formatFailureMessage(
                "Expected sub-range", prettyPrint(expected),
                "Received", prettyPrint(received),
            ));
        }
        else
        {
            fail(formatFailureMessage(
                "Expected element", prettyPrint(expected),
                "Received", prettyPrint(received),
            ));
        }
    }

    static if (isInputRange!TReceived && is(ElementType!TReceived))
    {
        /// ditto
        public void toContain(bool delegate(const(ElementType!TReceived)) predicate)
        {
            completed = true;

            if (received.any!predicate) return;

            fail(
                "Received: ".color(fg.red) ~ prettyPrint(received) ~ "\n" ~
                "None of the elements in the received array satisfy the predicate."
            );
        }
    }


    /// Succeeds if all elements in `received` are equal to
    /// `expected`, or satisfy `predicate`.
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

        if (all!(e => e == expected)(received)) return;

        size_t[] failingIndices;

        foreach (size_t index, ElementType!TReceived element; received)
        {
            if (element != expected)
            {
                failingIndices ~= index;
            }
        }

        size_t[2][] failingRanges = failingIndices.map!(e => cast(size_t[2])[e, e + 1]).array;

        fail(formatFailureMessage(
            "Expected", prettyPrint(expected),
            "Received", prettyPrintHighlightedArray(received, failingRanges),
        ));
    }


    // TODO: Indexed foreach doesn't work with nullables
    static if (isInputRange!TReceived && is(ElementType!TReceived) && !is(TReceived : Nullable!Payload, Payload))
    {
        /// ditto
        public void toContainOnly(bool delegate(const(ElementType!TReceived)) predicate)
        {
            completed = true;

            if (received.all!predicate) return;

            size_t[] failingIndices;

            foreach (size_t index, const(ElementType!TReceived) element; received)
            {
                if (!predicate(element))
                {
                    failingIndices ~= index;
                }
            }

            size_t[2][] failingRanges = failingIndices.map!(e => cast(size_t[2])[e, e + 1]).array;

            fail(
                "Received: ".color(fg.red) ~ prettyPrintHighlightedArray(received, failingRanges) ~ "\n" ~
                "Some elements in the received array do not satisfy the predicate."
            );
        }
    }
}
