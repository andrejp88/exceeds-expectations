module exceeds_expectations_test.to_be_of_type;

import exceeds_expectations;
import exceeds_expectations_test;


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

@("A complicated inheritance tree")
unittest
{
    interface I1 {}
    interface I2 {}
    interface I3 {}
    interface IA {}
    interface IB {}
    interface IC {}
    interface ICC : IC {}

    class CA : IA {}
    class CB3 : IB, I3 {}
    class CBC3C : CB3, ICC {}
    class CAC2 : CA, IC, I2 {}


    CBC3C c = new CBC3C();

    shouldFail(
        expect(c).toBeOfType!I2
    );
}

@("null")
unittest
{
    // The purpose of toBeOfType is to check received's actual type at runtime.
    // If received is null, it doesn't make sense to say it is the given type,
    // because the type of null is (1) not possible to name in D and (2) the
    // bottom (ish?) type, so it is technically everything. We want this to
    // fail because if, say, a function call returns null, then it didn't
    // really return what was expected of it.

    Object o = null;

    shouldFail(
        expect(o).toBeOfType!Object
    );
}
