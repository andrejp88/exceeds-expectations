# exceeds-expectations

exceeds-expectations is an assertion library for the D programming language. It uses the `expect(___).to___()` style used by Jest and Chai.

## Usage

To get started, add exceeds-expectations as a unittest dependency to your project:

```sdl
configuration "unittest" {
    dependency "exceeds-expectations" version="<current version>"
    stringImportPaths "."
}
```

ℹ️ The `stringImportPaths "."` is used by exceeds-expectations to point at the lines of code where an expectation failed.

⚠️ If you run into problems with `stringImportPaths "."`, try using `dflags "-J."` instead.

Now you can write your unittests in an easily legible format using convenient assertions.

### Examples

#### Equality & Identity
```d
unittest
{
    Pencil pencil = new Pencil();
    Pencil anotherPencil = cloneObject(pencil);

    expect(anotherPencil).toEqual(pencil);
    expect(anotherPencil).not.toBe(pencil);
}
```

#### Floating Point Comparison
```d
unittest
{
    real tempCelsius = 23.0;
    real tempFahrenheit = celsiusToFahrenheit(tempCelsius);

    expect(tempFahrenheit).toApproximatelyEqual(73.4);
}
```


#### Arbitrary Predicates

When the method you need isn't in the library... yet 😉

```d
unittest
{
    static bool someConvolutedRequirement(int n)
    {
        return (n < 233 && n >= -48 && n % 2 == 0) || (n > 692 && n < 10_002 && n % 3 == 1);
    }

    int myNumber = 8;

    expect(myNumber).toSatisfy(&someConvolutedRequirement);

    // Or:

    expect(8).toSatisfyAny(
        (n) => n < 233 && n >= -48 && n % 2 == 0,
        (n) => n > 692 && n < 10_002 && n % 3 == 1
    );

    // .toSatisfyAll() is also available
}
```


## Why?
Existing assertion libraries (such as [dshould](https://code.dlang.org/packages/dshould) and [fluent-asserts](https://code.dlang.org/packages/fluent-asserts)) rely on [unified function call syntax](https://dlang.org/spec/function.html#pseudo-member) to achieve their natural, sentence-like syntax. Unfortunately, [DCD does not support auto-completions using the UFCS syntax](https://github.com/dlang-community/DCD#status). This means that IDEs cannot automatically suggest assertions for you.

In exceeds-expectations, assertions begin with a call to `expect()`, which returns an "Expectation" object whose member functions are visible to DCD.
