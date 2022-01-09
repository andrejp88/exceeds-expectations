module exceeds_expectations.test.expect.to_be_null;

import exceeds_expectations;
import exceeds_expectations.test;
import std.typecons;


@("A Nullable!int with no value passes")
unittest
{
    Nullable!int n;
    expect(n).toBeNull();
}

@("A Nullable!int with a value fails")
unittest
{
    Nullable!int n = 1;
    shouldFail(
        expect(n).toBeNull()
    );
}

@("A NullableRef!int with no value passes")
unittest
{
    NullableRef!int n;
    expect(n).toBeNull();
}

@("A NullableRef!int with a value fails")
unittest
{
    int i = 22;
    NullableRef!int n = &i;
    shouldFail(
        expect(n).toBeNull()
    );
}

@("A null int* passes")
unittest
{
    int* p = null;
    expect(p).toBeNull();
}

@("A non-null int* fails")
unittest
{
    int i = 3;
    int* p = &i;
    shouldFail(
        expect(p).toBeNull()
    );
}
