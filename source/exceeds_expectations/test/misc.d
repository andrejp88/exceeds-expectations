module exceeds_expectations.test.misc;

import exceeds_expectations;
import exceeds_expectations.exceptions;


@("Throw an InvalidExpectationException if except called but assertion not completed")
unittest
{
    try
    {
        expect(2);
    }
    catch (InvalidExpectationException e)
    {
        return;
    }

    assert(false, "Expected to catch an InvalidExpectationException but didn't.");
}
