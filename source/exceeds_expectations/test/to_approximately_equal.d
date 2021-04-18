module exceeds_expectations.test.to_approximately_equal;

import exceeds_expectations;
import exceeds_expectations.test;

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

@("float toApproximatelyEqual int")
unittest
{
    expect(float(2.9999999999)).toApproximatelyEqual(int(3));
}
