module exceeds_expectations.test.to_contain_only;

import exceeds_expectations;
import exceeds_expectations.test;
import std.range;


@("single element array success")
unittest
{
    int[] arr = [1];
    expect(arr).toContainOnly(1);
}

@("single element array failure")
unittest
{
    int[] arr = [1];

    shouldFail(
        expect(arr).toContainOnly(2)
    );
}

@("multiple element array success")
unittest
{
    expect(repeat(999).take(20).array).toContainOnly(999);
}

@("multiple element array failure")
unittest
{
    shouldFail(
        expect(repeat(999).take(20).array ~ [998]).toContainOnly(999)
    );
}
