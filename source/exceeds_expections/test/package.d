module exceeds_expections.test;

import exceeds_expections;
import std.stdio;

version (unittest)
{
    package void showMessage(lazy void dg)
    {
        try
        {
            dg;
            assert(false, "Expected an exception but received none.");
        }
        catch (EEException e)
        {
            writeln(e.message);
        }
    }
}
