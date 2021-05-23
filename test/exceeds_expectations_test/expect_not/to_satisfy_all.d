module exceeds_expectations_test.expect_not.to_satisfy_all;

import exceeds_expectations;
import exceeds_expectations_test;


@("toSatisfyAll")
unittest
{
    expect(4).not.toSatisfyAll(i => i == 4, i => i == 5);
}

@("toSatisfyAll, but does")
unittest
{
    shouldFail(expect(4).not.toSatisfyAll(i => i == 4, i => i <= 5));
}

@("toSatisfyAll, but an exception is thrown, despite otherwise succeeding")
unittest
{
    int delegate() dg = { throw new Exception("Oops"); };

    shouldFail(
        expect(dg).not.toSatisfyAll(
            p => false,
            p => p() <= 5
        )
    );
}
