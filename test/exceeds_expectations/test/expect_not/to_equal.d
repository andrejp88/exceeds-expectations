module exceeds_expectations.test.expect_not.to_equal;

import exceeds_expectations;
import exceeds_expectations.test;


@("toEqual")
unittest
{
    expect(4).not.toEqual(5);
}

@("toEqual, but does")
unittest
{
    shouldFail(expect(4).not.toEqual(4));
}

@("Arrays")
unittest
{
    string[] witches = ["Esmerelda Weatherwax", "Gytha Ogg", "Magrat Garlick"];

    expect(witches).not.toEqual(["Mustrum Ridcully"]);
}

@("Associative arrays")
unittest
{
    string[string] aa = [
        "name": "Mustrum",
        "surname": "Ridcully",
    ];

    expect(aa).not.toEqual([
        "name": "Esmerelda",
        "surname": "Weatherwax",
    ]);
}
