module exceeds_expectations_test.expect_not.to_be;

import exceeds_expectations;
import exceeds_expectations_test;


@("toBe")
unittest
{
    expect(4).not.toBe(5);
}

@("toBe, but does")
unittest
{
    shouldFail(expect(4).not.toBe(4));
}
