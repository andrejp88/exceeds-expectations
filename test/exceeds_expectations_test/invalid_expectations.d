module exceeds_expectations_test.invalid_expectations;

import exceeds_expectations;
import exceeds_expectations_test;


@("Throw an InvalidExpectationException if except called but assertion not completed")
unittest
{
    shouldBeInvalid(
        expect(2)
    );
}

@("Double negative should fail to compile")
unittest
{
    static assert(!__traits(compiles, expect(4).not.not));
}
