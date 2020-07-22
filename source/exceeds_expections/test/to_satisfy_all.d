module exceeds_expections.test.to_satisfy_all;

import exceeds_expections;
import exceeds_expections.test;


@("Integer 3/3")
unittest
{
    expect(5).toSatisfyAll(
        e => e < 10,
        e => e > 2,
        e => e % 2 == 1
    );
}

@("Integer 2/3")
unittest
{
    shouldFail(
        expect(5).toSatisfyAll(
            e => e < 10,
            e => e > 8,
            e => e % 2 == 1
        )
    );
}

@("Integer 1/3")
unittest
{
    shouldFail(
        expect(5).toSatisfyAll(
            e => e < 3,
            e => e > 8,
            e => e % 2 == 1
        )
    );

}

@("Integer 1/4")
unittest
{
    shouldFail(
        expect(5).toSatisfyAll(
            e => e < 3,
            e => e > 8,
            e => e % 2 == 0,
            e => true
        )
    );
}

@("Integer 0/4")
unittest
{
    shouldFail(
        expect(5).toSatisfyAll(
            e => e < 3,
            e => e > 8,
            e => e % 2 == 0,
            e => false
        )
    );
}
