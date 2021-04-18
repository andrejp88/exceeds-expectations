module exceeds_expectations.expectation;

import colorize;
import exceeds_expectations.eeexception;
import exceeds_expectations.utils;
import std.algorithm;
import std.array;
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
    return Expectation!T(received, filePath, line, false);
}


/**
 *  Wraps any object and allows assertions to be run.
 */
public struct Expectation(TReceived)
{
    private const(TReceived) received;
    private immutable string filePath;
    private immutable size_t line;
    private immutable bool negated;
    private bool completed = false;

    private this(const(TReceived) received, string filePath, size_t line, bool negated)
    {
        this.received = received;
        this.filePath = filePath;
        this.line = line;
        this.negated = negated;
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

    /// Negates the expectation
    public Expectation!(TReceived) not()
    {
        completed = true; // Because a new expectation is returned, and this one will be discarded.

        if (!negated)
        {
            return Expectation(received, filePath, line, true);
        }
        else
        {
            throw new EEException(
                `Found multiple "not"s at ` ~ filePath ~ "(" ~ line.to!string ~ "): \n" ~
                "\n" ~ formatCode(readText(filePath), line, 2) ~ "\n",
                filePath, line
            );
        }
    }

    private enum bool canCompareForEquality(L, R) = __traits(compiles, rvalueOf!L == rvalueOf!R);

    /// Throws an [EEException] unless `received == expected`.
    public void toEqual(TExpected)(const auto ref TExpected expected)
    if (canCompareForEquality!(TReceived, TExpected))
    {
        completed = true;

        if (!negated)
        {
            if (received != expected)
            {
                throwEEException(
                    formatDifferences(stringify(expected), stringify(received))
                );
            }
        }
        else
        {
            if (received == expected)
            {
                throwEEException(
                    formatDifferences(stringify(expected), stringify(received))
                );
            }
        }
    }

    /// Throws an [EEException] unless `predicate(received)` returns true.
    public void toSatisfy(bool delegate(const(TReceived)) predicate)
    {
        completed = true;

        if (!negated)
        {
            if (!predicate(received))
            {
                throwEEException(
                    "Received: " ~ stringify(received).color(fg.light_red)
                );
            }
        }
        else
        {
            if (predicate(received))
            {
                throwEEException(
                    "Received: " ~ stringify(received).color(fg.light_red)
                );
            }
        }
    }

    /// Throws an [EEException] unless `predicate(received)` returns true for all `predicates`.
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

        if (!negated)
        {
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

                throwEEException(
                    "Received: " ~ stringify(received).color(fg.light_red),
                    description
                );
            }
        }
        else
        {
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
    }

    /// Throws an [EEException] if `predicate(received)` returns false for all `predicates`.
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

        if (!negated)
        {
            auto results = predicates.map!(p => p(received));
            immutable size_t numPassed = count!(e => e)(results);

            if(numPassed == 0)
            {
                throwEEException(
                    "Received: " ~ stringify(received).color(fg.light_red)
                );
            }
        }
        else
        {
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
    }

    /**
     * Throws an [EEException] unless `received.isClose(expected, maxRelDiff, maxAbsDiff)`.
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

        if (!negated)
        {
            if (!received.isClose(expected, maxRelDiff, maxAbsDiff))
            {
                throwEEException(
                    formatApproxDifferences(received, expected, maxRelDiff, maxAbsDiff)
                );
            }
        }
        else if (negated)
        {
            if (received.isClose(expected, maxRelDiff, maxAbsDiff))
            {
                throwEEException(
                    formatApproxDifferences(received, expected, maxRelDiff, maxAbsDiff)
                );
            }
        }
    }

    /// Throws an [EEException] unless `received is expected`.
    public void toBe(TExpected)(const auto ref TExpected expected)
    {
        completed = true;

        if (!negated)
        {
            if (received !is expected)
            {
                throwEEException(
                    "",
                    "Arguments do not reference the same object (received !is expected)."
                );
            }
        }
        else
        {
            if (received is expected)
            {
                throwEEException(
                    "",
                    "Arguments reference the same object (received is expected)"
                );
            }
        }
    }

    /// Throws [EEException] unless `received` is a sub-type of `TExpected`.
    public void toBeOfType(TExpected)()
    if ((is(TExpected == class) || is(TExpected == interface)) &&
        (is(TReceived == class) || is(TReceived == interface)))
    {
        completed = true;

        if (!negated)
        {
            if (!cast(TExpected) received)
            {
                throwEEException(
                    formatDifferences(
                        "`" ~ typeid(TExpected).to!string ~ "`",
                        "`" ~ received.to!string ~ "`"
                    ),
                    "Received value does not extend the expected type."
                );
            }
        }
        else
        {
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
    }

    /// If `received` throw a `TExpected` (or one of its sub-types),
    /// it is caught and this function exits successfully.
    /// If `received` does not throw a `TExpected`, but does throw
    /// something else, an EEException is thrown.
    /// If `received` doesn't throw anything, an EEException is thrown.
    public void toThrow(TExpected : Throwable = Throwable)()
    if (isCallable!TReceived)
    {
        completed = true;

        if (!negated)
        {
            try
            {
                received();
            }
            catch (Throwable e)             // @suppress(dscanner.suspicious.catch_em_all)
            {
                if (cast(TExpected) e) return;

                throwEEException(
                    formatDifferences(
                        typeid(TExpected).name,
                        typeid(e).name
                    )
                );
            }

            throwEEException(
                formatDifferences(
                    typeid(TExpected).name,
                    "Nothing was thrown"
                )
            );
        }
        else
        {
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

            return;
        }
    }
}
