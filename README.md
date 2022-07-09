[![](https://gitlab.com/andrej88/exceeds-expectations/-/raw/v0.9.5/readme-resources/gitlab-icon-rgb.svg) Main Repo](https://gitlab.com/andrej88/exceeds-expectations)   ·   [![](https://gitlab.com/andrej88/exceeds-expectations/-/raw/v0.9.5/readme-resources/github-icon.svg) Mirror](https://github.com/andrejp88/exceeds-expectations)   ·   [![](https://gitlab.com/andrej88/exceeds-expectations/-/raw/v0.9.5/readme-resources/dub-logo-small.png) Dub Package Registry](https://code.dlang.org/packages/exceeds-expectations)   ·   [![](https://gitlab.com/andrej88/exceeds-expectations/-/raw/v0.9.5/readme-resources/documentation-icon.svg) Documentation](https://exceeds-expectations.dpldocs.info/exceeds_expectations.expect.Expect.html)

# exceeds-expectations

exceeds-expectations is an assertions library for the D programming language. It uses the `expect(___).to___()` style used by Jest and Chai.

It gets along well with IDE autocompletion:

![After calling "expect" and typing ".to", VSCode shows a list of available assertions.](https://gitlab.com/andrej88/exceeds-expectations/-/raw/v0.9.5/readme-resources/ide-completion.png)

Failing tests show clear and informative messages:

![Console output of a failing expectation showing the expected value, the received value, and a snippet of code surrounding the expectation.](https://gitlab.com/andrej88/exceeds-expectations/-/raw/v0.9.5/readme-resources/tomatch-failure.png)

## Usage

To get started, add exceeds-expectations as a unittest dependency to your project:

`dub.sdl`:

```sdl
configuration "unittest" {
    dependency "exceeds-expectations" version="<current version>"
}
```

`dub.json`:

```json
"configurations": [
    {
        "name": "unittest",
        "dependencies": {
            "exceeds-expectations": "<current version>"
        }
    }
]
```

Now just `import exceeds_expectations` where you need it. Some example usages can be found in the next section.

This library was made for writing tests, but it can be used anywhere. Add it as a regular dependency and use it wherever (for example, instead of an `enforce`).

### Examples

A full list of expectations can be found in the [documentation](https://exceeds-expectations.dpldocs.info/exceeds_expectations.expect.Expect.html#function). Here are a few of them:

Equality and identity:
```d
unittest
{
    Pencil pencil = new Pencil();
    Pencil anotherPencil = cloneObject(pencil);

    expect(anotherPencil).toEqual(pencil);
    expect(anotherPencil).not.toBe(pencil);
}
```

Floating point comparison:
```d
unittest
{
    real tempCelsius = 23.0;
    real tempFahrenheit = celsiusToFahrenheit(tempCelsius);

    expect(tempFahrenheit).toApproximatelyEqual(73.4);
}
```


Arbitrary predicates, for when the method you need isn't in the library... yet.

```d
unittest
{
    static bool needlesslyComplicatedRequirement(int n)
    {
        return (
            (n > 233 || n <= -48 || n % 2 == 0) &&
            (n < 692 || n > 10_002 || n % 3 == 1)
        );
    }

    expect(8).toSatisfy(&needlesslyComplicatedRequirement);

}


// This example can also be written using toSatisfyAll...
unittest
{    
    expect(8).toSatisfyAll(
        (n) => n > 233 || n <= -48 || n % 2 == 0,
        (n) => n < 692 || n > 10_002 || n % 3 == 1
    );
}


// ...or toSatisfyAny.
unittest
{
    expect(8).toSatisfyAny(
        (n) => n > 233,
        (n) => n <= -48,
        (n) => n % 2 == 0
    );

    expect(8).toSatisfyAny(
        (n) => n < 692,
        (n) => n > 10_002,
        (n) => n % 3 == 1
    );
}
```


## Why another assertion library?

There are already a few ways to do assertions in D.

The language itself comes with the [assert expression](https://dlang.org/spec/expression.html#AssertExpression). Unfortunately, these are quite limited and don't tell you much when an assertion fails.

At the time exceeds-expectations was born, some libraries already existed that offered a more natural syntax and more useful failure messages. The two with the highest scores on code.dlang.org are [fluent-asserts](https://code.dlang.org/packages/fluent-asserts) and [dshould](https://code.dlang.org/packages/dshould). Both used the `X.should...` syntax, which results in readable assertions that resemble natural English.

This syntax works because of D's [unified function call syntax](https://dlang.org/spec/function.html#pseudo-member). Unfortunately, [DCD does not support auto-completions using the UFCS syntax](https://github.com/dlang-community/DCD#status). This means that IDEs cannot automatically suggest assertions for you. This was true when exceeds-expecations was created and is still true as of this writing.

To enable a more pleasant experience when using IDEs, assertions from exceeds-expectations begin with a call to `expect()`, which returns an "Expect" struct whose member functions are visible to DCD.

Version 14 of fluent-asserts (in alpha as of April 2021) also offers the `expect()` form like in exceed-expectations.
