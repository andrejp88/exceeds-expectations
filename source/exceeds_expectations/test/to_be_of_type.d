module exceeds_expectations.test.to_be_of_type;

import exceeds_expectations;
import exceeds_expectations.test;


@("Class can cast to its interface")
unittest
{
    interface A {}

    class B : A {}

    A a = new B();
    B b = new B();

    expect(a).toBeOfType!A;
    expect(a).toBeOfType!B;
    expect(b).toBeOfType!B;
    expect(b).toBeOfType!B;
}

@("Sub-class of an interface cannot cast to a different sub-class")
unittest
{
    interface A {}

    class B : A {}
    class C : A {}

    A a = new B();

    shouldFail(expect(a).toBeOfType!C);
}

@("Negation")
unittest
{
    interface A {}

    class B : A {}
    class C : A {}

    A a = new B();

    expect(a).not.toBeOfType!C;
    shouldFail(expect(a).not.toBeOfType!B);
}
