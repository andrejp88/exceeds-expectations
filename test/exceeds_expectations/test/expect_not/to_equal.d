module exceeds_expectations.test.expect_not.to_equal;

import exceeds_expectations;
import exceeds_expectations.test;


@("toEqual")
unittest
{
    expect(4).not.toEqual(5);
}

@("toEqual, but does")
unittest
{
    shouldFail(expect(4).not.toEqual(4));
}
