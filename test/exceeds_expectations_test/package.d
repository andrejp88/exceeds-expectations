module exceeds_expectations_test;

import exceeds_expectations.exceptions;

import std.conv;
import std.stdio;


package void shouldFail(lazy void dg, string file = __FILE__, int line = __LINE__)
{
    try
    {
        dg();
        assert(false, "\nExpectation was supposed to fail but didn't: " ~ file ~ "(" ~ line.to!string ~ ")");
    }
    catch (FailingExpectationException e)
    {
        debug(SHOW_MESSAGES) writeln(e.message);
    }
}

package void shouldBeInvalid(lazy void dg, string file = __FILE__, int line = __LINE__)
{
    try
    {
        dg();
        assert(false, "\nInvalid expectation wasn't caught: " ~ file ~ "(" ~ line.to!string ~ ")");
    }
    catch (InvalidExpectationException e)
    {
        debug(SHOW_MESSAGES) writeln(e.message);
    }
}
