module exceeds_expectations.test.to_match;

import exceeds_expectations;
import exceeds_expectations.test;


@("Full RegExp match")
unittest
{
    expect("1234").toMatch(`\d\d\d\d`);
}

@("Full RegExp failure")
unittest
{
    shouldFail(
        expect("1234").toMatch(`\s\s\s\s`)
    );
}

@("Partial regex match")
unittest
{
    expect("1234").toMatch(`2\d`);
}


@("Partial regex failure")
unittest
{
    shouldFail(
        expect("1234").toMatch(`2\D`)
    );
}

@("Complex regex success")
unittest
{
    expect("botanical in berkshire, zoological in zzyzx").toMatch(`(?<!botanical) in (?=[xyz]{5})`);
}

@("Complex regex failure")
unittest
{
    shouldFail(
        expect("botanical in zzyzx, zoological in berkshire").toMatch(`(?<!botanical) in (?=[xyz]{5})`)
    );
}

@("Multiline regex success")
unittest
{
    expect("botanical in berkshire,\nzoological in zzyzx").toMatch(`^[a-z]+ in (?=[xyz]{5})`, "m");
}

@("Multiline regex failure")
unittest
{
    shouldFail(
        expect("botanical in berkshire,\nzoological in zzyzx").toMatch(`^[a-z]+ in (?=[xyz]{5})`)
    );
}

@("Case-insensitive regex success")
unittest
{
    expect("botanical in berkshire, zoological in zzyzx").toMatch(`BERKSHIRE`, "i");
}

@("Case-insensitive regex failure")
unittest
{
    shouldFail(
        expect("botanical in berkshire, zoological in zzyzx").toMatch(`BERKSHIRE`)
    );
}

@("Throw an InvalidExpectationException if the regex is invalid")
unittest
{
    shouldBeInvalid(
        expect("botanical in berkshire, zoological in zzyzx").toMatch(`[a-z`)
    );
}
