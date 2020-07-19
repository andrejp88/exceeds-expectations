module exceeds_expections.test;

import exceeds_expections;

import std.conv;
import std.stdio;


package void shouldFail(lazy void dg, string file = __FILE__, int line = __LINE__)
{
    try
    {
        dg();
        assert(false, "\nExpectation was supposed to fail but didn't: " ~ file ~ "(" ~ line.to!string ~ ")");
    }
    catch (EEException e)
    {
        debug(SHOW_MESSAGES) writeln(e.message);
    }
}
