module exceeds_expectations.test.misc;

import exceeds_expectations;
import exceeds_expectations.test;


@("Throw an exception if except called but assertion not completed")
unittest
{
    shouldFail(expect(2));
}
