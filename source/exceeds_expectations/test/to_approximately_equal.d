module exceeds_expectations.test.to_approximately_equal;

import exceeds_expectations;
import exceeds_expectations.test;

@("float toApproximatelyEqual float")
unittest
{
    expect(float(2.9999999999)).toApproximatelyEqual(float(3.0));

    shouldFail(
        expect(2.9999999999).toEqual(3.0)
    );
}

@("float !toApproximatelyEqual float")
unittest
{
    shouldFail(expect(2.9).toApproximatelyEqual(3.0));
}

@("float toApproximatelyEqual int")
unittest
{
    expect(float(2.9999999999)).toApproximatelyEqual(int(3));
}
