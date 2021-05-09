module exceeds_expectations.test.misc;

import exceeds_expectations;
import exceeds_expectations.test;


@("Throw an InvalidExpectationException if except called but assertion not completed")
unittest
{
    shouldBeInvalid(
        expect(2)
    );
}
