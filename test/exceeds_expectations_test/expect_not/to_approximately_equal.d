module exceeds_expectations_test.expect_not.to_approximately_equal;

import exceeds_expectations;
import exceeds_expectations_test;


@("toApproximatelyEqual")
unittest
{
    expect(4).not.toApproximatelyEqual(5.0);
}

@("toApproximatelyEqual, but does")
unittest
{
    shouldFail(expect(4).not.toApproximatelyEqual(4.0));
}

@("toApproximatelyEqual with custom maxRelDiff and maxAbsDiff")
unittest
{
    expect(10.0).not.toApproximatelyEqual(9.0, 0.05, 0.9);
}

@("toApproximatelyEqual, but does, with custom maxRelDiff and maxAbsDiff")
unittest
{
    shouldFail(
        expect(10.0).not.toApproximatelyEqual(9.2, 0.05, 0.9)
    );
}
