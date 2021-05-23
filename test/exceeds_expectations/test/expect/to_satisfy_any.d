module exceeds_expectations.test.expect.to_satisfy_any;

import exceeds_expectations;
import exceeds_expectations.test;


@("Integer 1/1")
unittest
{
    expect(3).toSatisfyAny(e => e == 3);
}

@("Integer 0/1")
unittest
{
    shouldFail(expect(-25).toSatisfyAny(e => e == 33));
}

@("Integer 2/2")
unittest
{
    expect(882).toSatisfyAny(
        n => n / 100 == 8,
        n => n / 10 == 88
    );
}

@("Integer 1/2")
unittest
{
    expect(333).toSatisfyAny(
        n => n % 111 == 0,
        n => n % 2 == 1
    );
}

@("Integer 0/2")
unittest
{
    shouldFail(
        expect(-532).toSatisfyAny(
            e => e > 0,
            e => e % 2 == 1
        )
    );
}

@("Integer 3/3")
unittest
{
    expect(0).toSatisfyAny(
        i => i < 100,
        i => i > -1,
        i => i == 0
    );
}

@("Integer 2/3")
unittest
{
    expect(5).toSatisfyAny(
        e => e < 10,
        e => e > 9,
        e => e % 2 == 1
    );
}

@("Integer 1/3")
unittest
{
    expect(0).toSatisfyAny(
        e => e == 2,
        e => e == 0,
        e => e == 1
    );
}

@("Integer 0/3")
unittest
{
    shouldFail(
        expect(5).toSatisfyAny(
            e => e < 3,
            e => e > 9,
            e => e % 2 == 0
        )
    );
}

@("char 1/2")
unittest
{
    expect('c').toSatisfyAny(c => c == 'c', c => c == 'd');
}

@("Failed due to exceptions in all")
unittest
{
    int delegate() dg = { throw new Exception("Oops"); };

    shouldFail(
        expect(dg).toSatisfyAny(
            result => result() == 4,
            result => result() != 8,
        )
    );
}

@("Fails due to an exception in just one, despite others succeeding")
unittest
{
    int delegate() dg = { throw new Exception("Oops"); };

    shouldFail(
        expect(dg).toSatisfyAny(
            result => true,
            result => result() == 4,
        )
    );
}
