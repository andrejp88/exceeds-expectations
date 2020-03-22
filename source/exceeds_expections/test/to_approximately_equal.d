module exceeds_expections.test.to_approximately_equal;

import exceeds_expections;
import exceeds_expections.test;

unittest
{
    expect(2.9999999999).toApproximatelyEqual(3.0);


    showMessage(
        expect(2.9999999999).toEqual(3.0)
    );
}

unittest
{
    showMessage(
        expect(2.9).toApproximatelyEqual(3.0)
    );
}
