module exceeds_expectations_test.expect_not.to_match;

import exceeds_expectations;
import exceeds_expectations_test;


@("toMatch simple")
unittest
{
    expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`zzyzx.*berkshire`);
}

@("toMatch simple, but does")
unittest
{
    shouldFail(
        expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`berkshire.*zzyzx`)
    );
}

@("toMatch complex")
unittest
{
    expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`(?<=z{3}y)z(?=x)`);
}

@("toMatch complex, but does")
unittest
{
    shouldFail(
        expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`(?<=z{2}y)z(?=x)`)
    );
}

@("toMatch multiline")
unittest
{
    expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`berkshire.*\n.*zzyzx`, "ms");
}

@("toMatch multiline, but does")
unittest
{
    shouldFail(
        expect("botanical in berkshire,\nzoological in zzyzx").not.toMatch(`berkshire.*\n.*zzyzx`, "ms")
    );
}

@("toMatch case-insensitive")
unittest
{
    expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`ZZYZX`);
}

@("toMatch case-insensitive, but does")
unittest
{
    shouldFail(
        expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`ZZYZX`, "i")
    );
}

@("toMatch throws an InvalidExpectationException if the regex is invalid")
unittest
{
    shouldBeInvalid(
        expect("botanical in berkshire, zoological in zzyzx").not.toMatch(`[a-z`)
    );
}
