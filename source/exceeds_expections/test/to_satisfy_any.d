module exceeds_expections.test.to_satisfy_any;

import exceeds_expections;
import exceeds_expections.test;


@("Integer 3/3")
unittest
{
    expect(0).toSatisfyAll(i => i < 100, i => i > -1, i => i == 0);
}

@("Integer 2/3")
unittest
{
    expect(5).toSatisfyAny(
        e => e < 10,
        e => e > 9,
        e => e % 2 == 1
    );
}

@("Integer 0/3")
unittest
{
    shouldFail(
        expect(5).toSatisfyAny(
            e => e < 3,
            e => e > 9,
            e => e % 2 == 0
        )
    );
}

@("char 1/2")
unittest
{
    expect('c').toSatisfyAny(c => c == 'c', c => c == 'd');
}
