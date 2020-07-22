module exceeds_expections.test.not;

import exceeds_expections;
import exceeds_expections.test;

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


@("toSatisfy")
unittest
{
    expect(4).not.toSatisfy(i => i == 5);
}

@("toSatisfy, but does")
unittest
{
    shouldFail(expect(4).not.toSatisfy(i => i == 4));
}


@("toSatisfyAny")
unittest
{
    expect(4).not.toSatisfyAny(i => i == 5, i => i == 3);
}

@("toSatisfyAny, but does")
unittest
{
    shouldFail(expect(4).not.toSatisfyAny(i => i == 5, i => i == 4));
}



@("toSatisfyAll")
unittest
{
    expect(4).not.toSatisfyAll(i => i == 4, i => i == 5);
}

@("toSatisfyAll, but does")
unittest
{
    shouldFail(expect(4).not.toSatisfyAll(i => i == 4, i => i <= 5));
}

@("Double negative should not be allowed")
unittest
{
    shouldFail(expect(4).not.not);
}
