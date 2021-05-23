module exceeds_expectations.test.expect_not.to_be_of_type;

import exceeds_expectations;
import exceeds_expectations.test;


@("toBeOfType")
unittest
{
    interface I {}
    class A : I {}
    class B : I {}

    expect(new A()).not.toBeOfType!B;
}

@("toBeOfType, but is that exact type")
unittest
{
    interface I {}
    class A : I {}

    I a = new A();

    shouldFail(expect(a).not.toBeOfType!A);
}

@("toBeOfType, but is a sub-type")
unittest
{
    interface I {}
    class A : I {}

    A a = new A();

    shouldFail(expect(a).not.toBeOfType!I);
}

@("toBeOfType received null")
unittest
{
    Object o = null;
    expect(o).not.toBeOfType!Object;
}
