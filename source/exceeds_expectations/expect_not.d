module exceeds_expectations.expect_not;

import colorize;
import exceeds_expectations.eeexception;
import exceeds_expectations.utils;
import std.algorithm;
import std.conv;
import std.file;
import std.math;
import std.range;
import std.traits;


/**
 * Provides negated versions of the usual expectations in [Expectation].
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
            throw new EEException(
                "`expect` was called but no assertion was made at " ~
                filePath ~ "(" ~ line.to!string ~ "): \n\n" ~
                formatCode(readText(filePath), line, 2) ~ "\n",
                filePath, line
            );
        }
    }


    private void throwEEException(string differences, string description = "")
    {
        string locationString = "Failing expectation at " ~ filePath ~ "(" ~ line.to!string ~ ")";

        throw new EEException(
            description,
            locationString,
            differences,
            filePath, line
        );
    }


    /// Throws an [EEException] unless `received != expected`.
    public void toEqual(TExpected)(const auto ref TExpected expected)
    if (canCompareForEquality!(TReceived, TExpected))
    {
        completed = true;

        if (received == expected)
        {
            throwEEException(
                formatDifferences(stringify(expected), stringify(received))
            );
        }
    }

    /// Throws an [EEException] if `predicate(received)` returns true.
    public void toSatisfy(bool delegate(const(TReceived)) predicate)
    {
        completed = true;

        if (predicate(received))
        {
            throwEEException(
                "Received: " ~ stringify(received).color(fg.light_red)
            );
        }
    }

    /// Throws an [EEException] if `predicate(received)` returns true for all given predicates.
    public void toSatisfyAll(bool delegate(const(TReceived))[] predicates...)
    {
        completed = true;

        if (predicates.length == 0)
        {
            throw new EEException(
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
            throwEEException(
                "Received: " ~ stringify(received).color(fg.light_red),
                "Received value satisfies all predicates."
            );
        }
    }

    /// Throws an [EEException] if `predicate(received)` returns false for any given predicate.
    public void toSatisfyAny(bool delegate(const(TReceived))[] predicates...)
    {
        completed = true;

        if (predicates.length == 0)
        {
            throw new EEException(
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
                        ) ~ stringifyArray(passingIndices) ~ " (first argument is index 0)."
                    )
                );

            throwEEException(
                "Received: " ~ stringify(received).color(fg.light_red),
                description
            );
        }

    }

    /**
     * Throws an [EEException] if `received.isClose(expected, maxRelDiff, maxAbsDiff)`.
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
            throwEEException(
                formatApproxDifferences(received, expected, maxRelDiff, maxAbsDiff)
            );
        }
    }

    /// Throws an [EEException] if `received is expected`.
    public void toBe(TExpected)(const auto ref TExpected expected)
    {
        completed = true;

        if (received is expected)
        {
            throwEEException(
                "",
                "Arguments reference the same object (received is expected)"
            );
        }
    }

    /// Throws [EEException] if `received` is a sub-type of `TExpected`.
    public void toBeOfType(TExpected)()
    if ((is(TExpected == class) || is(TExpected == interface)) &&
        (is(TReceived == class) || is(TReceived == interface)))
    {
        completed = true;

        if (cast(TExpected) received)
        {
            throwEEException(
                formatDifferences(
                    "Not `" ~ typeid(TExpected).to!string ~ "`",
                    "    `" ~ received.to!string ~ "`"
                ),
                "Received value extends the type but was not expected to."
            );
        }
    }

    /// If `received` throws a `TExpected` (or one of its sub-types),
    /// an [EEException] is thrown.
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

            TypeInfo_Class receivedTypeInfo = typeid(e);
            TypeInfo_Class expectedTypeInfo = typeid(TExpected);

            if (receivedTypeInfo.name == expectedTypeInfo.name)
            {
                throwEEException(
                    formatDifferences(
                        "Not " ~ expectedTypeInfo.name,
                        "    " ~ receivedTypeInfo.name
                    )
                );
            }
            else
            {
                TypeInfo_Class[] superClasses;
                TypeInfo_Class current = receivedTypeInfo.base;
                enum objectTypeId = typeid(Object);

                while (current != objectTypeId)
                {
                    superClasses ~= current;

                    if (current == expectedTypeInfo) break;

                    current = current.base;
                }

                string superClassesTrace = fold!(
                    (string acc, TypeInfo_Class ti) => acc ~ "\n           <: " ~ ti.name
                )(superClasses, "");

                throwEEException(
                    formatDifferences(
                        "Not " ~ expectedTypeInfo.name,
                        "    " ~ receivedTypeInfo.name ~ superClassesTrace
                    )
                );
            }
        }
    }
}
