module exceeds_expectations_test.misc;

import exceeds_expectations;
import exceeds_expectations_test;


@("Throw an InvalidExpectationException if except called but assertion not completed")
unittest
{
    shouldBeInvalid(
        expect(2)
    );
}
