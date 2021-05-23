module exceeds_expectations_test.expect_not.to_satisfy_any;

import exceeds_expectations;
import exceeds_expectations_test;


@("toSatisfyAny")
unittest
{
    expect(4).not.toSatisfyAny(i => i == 5, i => i == 3);
}

@("toSatisfyAny, but does")
unittest
{
    shouldFail(expect(4).not.toSatisfyAny(i => i == 5, i => i == 4));
}

@("toSatisfyAny, but an exception is thrown, despite otherwise succeeding")
unittest
{
    int delegate() dg = { throw new Exception("Oops"); };

    shouldFail(
        expect(dg).not.toSatisfyAny(
            p => false,
            p => p() <= 5
        )
    );
}
