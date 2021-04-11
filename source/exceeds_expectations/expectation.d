module exceeds_expectations.expectation;

import colorize;
import exceeds_expectations.eeexception;
import exceeds_expectations.utils;
import std.algorithm;
import std.array;
import std.conv;
import std.math;
import std.range;
import std.traits;


/**
 *	Initiates the expectation chain.
 *
 *  TODO: Try to make this auto-ref
 */
public Expectation!(T, file) expect(T, string file = __FILE__)(const T actual, size_t line = __LINE__)
{
    return Expectation!(T, file)(actual, line, false);
}


/**
 *  Wraps any object and allows assertions to be run.
 */
public struct Expectation(TReceived, string file = __FILE__)
{
    private const(TReceived) received;

    private immutable size_t line;
    private enum string fileContents = import(file);
    private immutable string expectationCodeLocation;
    private immutable string expectationCodeExcerpt;
    private immutable bool negated;
    private bool completed = false;


    private this(const(TReceived) received, size_t line, bool negated)
    {
        this.received = received;
        this.line = line;
        this.expectationCodeLocation = "Failing expectation at " ~ file ~ "(" ~ line.to!string ~ ")";
        this.expectationCodeExcerpt = formatCode(fileContents, line, 2);
        this.negated = negated;
    }

    ~this()
    {
        if (!completed)
        {
            throw new EEException(
                "`expect` was called but no assertion was made at " ~
                file ~ "(" ~ line.to!string ~ "): \n\n" ~
                formatCode(fileContents, line, 2) ~ "\n",
                file, line
            );
        }
    }

    private void throwEEException(string differences, string description = "")
    {
        throw new EEException(
            description,
            expectationCodeLocation,
            expectationCodeExcerpt,
            differences,
            file, line
        );
    }

    /// Negates the expectation
    public Expectation!(TReceived, file) not()
    {
        completed = true; // Because a new expectation is returned, and this one will be discarded.

        if (negated) throw new EEException(
            `Found multiple "not"s at ` ~ file ~ "(" ~ line.to!string ~ "): \n" ~
            "\n" ~ formatCode(fileContents, line, 2) ~ "\n",
            file, line
        );

        return Expectation(received, line, true);
    }

    private enum bool canCompareForEquality(L, R) = __traits(compiles, rvalueOf!L == rvalueOf!R);

    /// Throws an [EEException] unless `received == expected`.
    public void toEqual(TExpected)(const auto ref TExpected expected)
    if (canCompareForEquality!(TReceived, TExpected))
    {
        completed = true;

        if ((received != expected) != negated)
        {
            throwEEException(
                formatDifferences(stringify(expected), stringify(received))
            );
        }
    }

    /// Throws an [EEException] unless `predicate(received)` returns true.
    public void toSatisfy(bool delegate(const(TReceived)) predicate)
    {
        completed = true;

        if ((!predicate(received)) != negated)
        {
            throwEEException(
                "Received: " ~ stringify(received).color(fg.light_red)
            );
        }
    }

    /// Throws an [EEException] unless `predicate(received)` returns true for all predicates in `predicates`.
    public void toSatisfyAll(bool delegate(const(TReceived))[] predicates...)
    {
        completed = true;

        if (predicates.length == 0)
        {
            throw new EEException(
                "Missing predicates at " ~ file ~ "(" ~ line.to!string ~ "): \n" ~
                "\n" ~ formatCode(fileContents, line, 2) ~ "\n",
                file, line
            );
        }

        if (predicates.length == 1)
        {
            toSatisfy(predicates[0]);
        }

        auto results = predicates.map!(p => p(received));

        if (negated)
        {
            immutable size_t numPassed = results.count!(e => e);

            if (numPassed < predicates.length) return;

            throwEEException(
                "Received: " ~ stringify(received).color(fg.light_red),
                "Received value satisfies all predicates."
            );
        }

        immutable size_t numFailures = results.count!(e => !e);

        if(numFailures == 0) return;

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

    /// Throws an [EEException] if `predicate(received)` returns false for all predicates in `predicates`.
    public void toSatisfyAny(bool delegate(const(TReceived))[] predicates...)
    {
        completed = true;

        if (predicates.length == 0)
        {
            throw new EEException(
                "Missing predicates at " ~ file ~ "(" ~ line.to!string ~ "): \n" ~
                "\n" ~ formatCode(fileContents, line, 2) ~ "\n",
                file, line
            );
        }

        if (predicates.length == 1)
        {
            toSatisfy(predicates[0]);
        }

        auto results = predicates.map!(p => p(received));

        immutable size_t numPassed = results.count!(e => e);

        if (!negated)
        {

            if(numPassed > 0) return;

            throwEEException(
                "Received: " ~ stringify(received).color(fg.light_red)
            );
        }

        if(numPassed == 0) return;

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

    /// Throws an [EEException] unless `received.approxEqual(expected, maxRelDiff, maxAbsDiff)`.
    public void toApproximatelyEqual(TExpected, F : real)(
        const auto ref TExpected expected,
        F maxRelDiff = 0.01,
        F maxAbsDiff = 1.0e-05
    )
    if (
        __traits(compiles, received.approxEqual(expected, maxRelDiff, maxAbsDiff))
    )
    {
        completed = true;

        if (!received.approxEqual(expected, maxRelDiff, maxAbsDiff) != negated)
        {
            immutable real relDiff = fabs((received - expected) / expected);
            immutable real absDiff = fabs(received - expected);
            string stringOfRelDiff = stringify(relDiff);
            string stringOfAbsDiff = stringify(absDiff);

            throwEEException(
                formatDifferences(stringify(expected), stringify(received)) ~ "\n" ~

                "Relative Difference: " ~ stringOfRelDiff.color(fg.yellow) ~
                (relDiff > maxRelDiff ? " > " : relDiff < maxRelDiff ? " < " : " = ") ~
                stringify(maxRelDiff) ~ " (maxRelDiff)\n" ~

                "Absolute Difference: " ~ stringOfAbsDiff.color(fg.yellow) ~
                (absDiff > maxAbsDiff ? " > " : absDiff < maxAbsDiff ? " < " : " = ") ~
                stringify(maxAbsDiff) ~ " (maxAbsDiff)\n"
            );
        }
    }

    /// Throws an [EEException] unless `received is expected`.
    public void toBe(TExpected)(const auto ref TExpected expected)
    {
        completed = true;

        if ((received !is expected) != negated)
        {
            throwEEException(
                "",
                negated ?
                "Arguments reference the same object (received is expected)" :
                "Arguments do not reference the same object (received !is expected)."
            );
        }
    }

    /// Throws [EEException] unless `received` is a sub-type of `TExpected`.
    public void toBeOfType(TExpected)()
    if ((is(TExpected == class) || is(TExpected == interface)) &&
        (is(TReceived == class) || is(TReceived == interface)))
    {
        completed = true;

        bool canCast = cast(TExpected) received ? true : false;
        if (negated == canCast)
        {
            throwEEException(
                formatDifferences(
                    (negated ? "Not " : "") ~ "`" ~ typeid(TExpected).to!string ~ "`",
                    (negated ? "    " : "") ~ "`" ~ received.to!string ~ "`"
                ),
                "Received value does not extend the expected type."
            );
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
