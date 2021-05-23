module exceeds_expectations_test.to_approximately_equal;

import exceeds_expectations;
import exceeds_expectations_test;

@("double toApproximatelyEqual double")
unittest
{
    expect(double(2.9999999999)).toApproximatelyEqual(double(3.0));

    shouldFail(
        expect(double(2.9999999999)).toEqual(double(3.0))
    );
}

@("float !toApproximatelyEqual float")
unittest
{
    shouldFail(
        expect(float(2.9)).toApproximatelyEqual(float(3.0))
    );
}

@("float toApproximatelyEqual float succeeds because of maxRelDiff")
unittest
{
    expect(10.0).toApproximatelyEqual(9.0, 0.15, 0.01);
}

@("float toApproximatelyEqual float succeeds because of maxAbsDiff")
unittest
{
    expect(10.0).toApproximatelyEqual(9.0, 0.01, 1.5);
}

@("float toApproximatelyEqual int")
unittest
{
    expect(float(2.9999999999)).toApproximatelyEqual(int(3));
}
