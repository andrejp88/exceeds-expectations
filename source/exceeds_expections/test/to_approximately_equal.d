module exceeds_expections.test.to_approximately_equal;

import exceeds_expections;
import exceeds_expections.test;

@("float approximatelyEqualTo float")
unittest
{
    expect(float(2.9999999999)).toApproximatelyEqual(float(3.0));
    expect(float(2.9999999999)).toBeCloseTo(float(3.0));

    showMessage(
        expect(2.9999999999).toEqual(3.0)
    );
}

@("float !toApproximatelyEqual float")
unittest
{
    showMessage(expect(2.9).toApproximatelyEqual(3.0));
}
