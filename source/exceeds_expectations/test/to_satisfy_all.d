module exceeds_expectations.test.to_satisfy_all;

import exceeds_expectations;
import exceeds_expectations.test;


@("Integer 1/1")
unittest
{
    expect(23).toSatisfyAll(e => e == 23);
}

@("Integer 0/1")
unittest
{
    shouldFail(expect(23).toSatisfyAll(e => e == 2));
}

@("Integer 2/2")
unittest
{
    expect(12).toSatisfyAll(n => n % 3 == 0, n => n % 4 == 0);
}

@("Integer 1/2")
unittest
{
    shouldFail(expect(10).toSatisfyAll(n => n % 3 == 0, n => n % 5 == 0));
}

@("Integer 0/2")
unittest
{
    shouldFail(expect(10).toSatisfyAll(n => n % 3 == 0, n => n % 4 == 0));
}

@("Integer 3/3")
unittest
{
    expect(5).toSatisfyAll(
        e => e < 10,
        e => e > 2,
        e => e % 2 == 1
    );
}

@("Integer 2/3")
unittest
{
    shouldFail(
        expect(5).toSatisfyAll(
            e => e < 10,
            e => e > 8,
            e => e % 2 == 1
        )
    );
}

@("Integer 1/3")
unittest
{
    shouldFail(
        expect(5).toSatisfyAll(
            e => e < 3,
            e => e > 8,
            e => e % 2 == 1
        )
    );

}

@("Integer 0/3")
unittest
{
    shouldFail(
        expect(5).toSatisfyAll(
            e => e < 3,
            e => e > 8,
            e => e % 2 == 0
        )
    );
}
