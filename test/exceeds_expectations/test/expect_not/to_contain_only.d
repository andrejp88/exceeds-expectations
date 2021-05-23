module exceeds_expectations.test.expect_not.to_contain_only;

import exceeds_expectations;
import exceeds_expectations.test;
import std.range;


@("toContainOnly, (single element)")
unittest
{
    int[] arr = [1];
    expect(arr).not.toContainOnly(0);
}

@("toContainOnly, (single element) but does")
unittest
{
    int[] arr = [1];

    shouldFail(
        expect(arr).not.toContainOnly(1)
    );
}

@("toContainOnly, (multiple elements)")
unittest
{
    expect(repeat(999).take(20).array ~ [998]).not.toContainOnly(999);
}

@("toContainOnly, (multiple elements) but does")
unittest
{
    shouldFail(
        expect(repeat(999).take(20).array).not.toContainOnly(999)
    );
}

@("toContainOnly, (predicate)")
unittest
{
    expect(iota(0, 20, 2).array ~ [3]).not.toContainOnly((int e) => e % 2 == 0);
}

@("toContainOnly, (predicate) but does")
unittest
{
    shouldFail(
        expect([2, 4, 6, 8, 10]).not.toContainOnly((int e) => e % 2 == 0)
    );
}
