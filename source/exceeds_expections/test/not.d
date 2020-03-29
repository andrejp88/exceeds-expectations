module exceeds_expections.test.not;

import exceeds_expections;
import exceeds_expections.test;

unittest
{
    expect(4).not.toEqual(5);
}

unittest
{
    expect(4).not.toBe(5);
}

unittest
{
    expect(4).not.toApproximatelyEqual(5.0);
}

unittest
{
    expect(4).not.toSatisfy(i => i == 5);
}

unittest
{
    expect(4).not.toSatisfyAny(i => i == 5, i => i == 3);
}

unittest
{
    expect(4).not.toSatisfyAll(i => i == 4, i => i == 5);
}

unittest
{
    showMessage(expect(4).not.toEqual(4));
}

unittest
{
    showMessage(expect(4).not.toBe(4));
}

unittest
{
    showMessage(expect(4).not.toApproximatelyEqual(4.0));
}

unittest
{
    showMessage(expect(4).not.toSatisfy(i => i == 4));
}

unittest
{
    showMessage(expect(4).not.toSatisfyAny(i => i == 5, i => i == 4));
}

unittest
{
    showMessage(expect(4).not.toSatisfyAll(i => i == 4, i => i <= 5));
}

unittest
{
    showMessage(expect(4).not.not);
}
