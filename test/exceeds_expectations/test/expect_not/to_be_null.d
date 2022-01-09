module exceeds_expectations.test.expect_not.to_be_null;

import exceeds_expectations;
import exceeds_expectations.test;
import std.typecons;


@("A Nullable!int with a value passes")
unittest
{
    Nullable!int n = 3;
    expect(n).not.toBeNull();
}

@("A Nullable!int with no value fails")
unittest
{
    Nullable!int n;
    shouldFail(
        expect(n).not.toBeNull()
    );
}

@("A NullableRef!int with a value passes")
unittest
{
    int i = 3;
    NullableRef!int n = nullableRef(&i);
    expect(n).not.toBeNull();
}

@("A NullableRef!int with no value fails")
unittest
{
    NullableRef!int n;
    shouldFail(
        expect(n).not.toBeNull()
    );
}

@("A non-null int* passes")
unittest
{
    int i = 3;
    int* p = &i; // &i will always love you
    expect(p).not.toBeNull();
}

@("A null int* fails")
unittest
{
    int* p = null;
    shouldFail(
        expect(p).not.toBeNull()
    );
}
