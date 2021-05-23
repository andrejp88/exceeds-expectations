module exceeds_expectations.test.expect_not.to_satisfy;

import exceeds_expectations;
import exceeds_expectations.test;


@("toSatisfy")
unittest
{
    expect(4).not.toSatisfy(i => i == 5);
}

@("toSatisfy, but an exception is thrown")
unittest
{
    int delegate() dg = { throw new Exception("Oops"); };

    shouldFail(
        expect(dg).not.toSatisfy(predicate => predicate() == 5)
    );
}

@("toSatisfy, but does")
unittest
{
    shouldFail(expect(4).not.toSatisfy(i => i == 4));
}
