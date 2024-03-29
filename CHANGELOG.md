# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.9.6] · 2022-11-20

### Fixed
- Fixed `toEqual` failing to compile when structs containing associative arrays.
- Allow caling `toEqual` when either operand is non-const.

---

## [0.9.5] · 2022-07-09

### Fixed
- Fixed `toEqual` failing to compile when comparing associative arrays.

---

## [0.9.4] · 2022-06-05

### Added
- Added overload of `toThrow` that checks for the right message.

### Changed
- Added quotation marks around string fields when printing struct and
  class instances.

### Docs
- Fixed release date of v0.9.3 in changelog

---

## [0.9.3] · 2022-06-01

### Fixed
- Fixed compilation under D v2.100

### Docs
- Fixed link in changelog to v0.9.3

---

## [0.9.2] · 2022-04-19

### Docs
- Removed accidental copy-paste entry in 0.9.1 section of changelog.

---

## [0.9.1] · 2022-04-19

### Fixed
- Stop trying to print fields of an object when it's null and its type isn't `typeof(null)`.

---

## [0.9.0] · 2022-01-09

### Added
- `toBeNull` for testing whether `Nullable` and `NullableRef` types contain a value or not.

### Docs
- Fixed changelog subheadings in section for version 0.8.0.

---

## [0.8.0] · 2021-10-03

### Changed
- `toContain` and `toContainOnly` can now infer the parameter type of the given predicate.
- The predicates given to `toContain` and `toContainOnly` now take the argument as `const`. Usages will have to change to either remove the type from the function literal or explicitly declare it as `const`.

### Fixed
- `wstring` or `dstring` are now handled correctly instead of causing a compile error.

### Docs
- Improved wording of expectations' doc comments.

---

## [0.7.1] · 2021-05-30

### Changed
- `not.toMatch` now highlights all matches in the received text. (#28)

### Fixed
- Source code snippets can now highlight the last line in the file without crashing.

---

## [0.7.0] · 2021-05-29

### Changed
- `toBe` shows prints difference between received and expected values (like toEqual) if it received non-reference types.
- Structs are now pretty-printed using the same format as class objects.
- The pretty-print format for classes and structs now includes the keyword `class` or `struct`.
- `FailingExpectationException` is now `FailingExpectationError` and extends `AssertError`. (#22)
- `InvalidExpectationException` is now `InvalidExpectationError` and extends `Error`.

### Fixed
- Text with yellow background highlighting no longer appears unreadable in most dark terminal themes. (#24)

---

## [0.6.0] · 2021-05-23

### Added
- `toMatch` for comparing a string against an expected regular expression. (#14)
- `toContain` for checking that an array contains a given element, sequence of elements, or an element matching a predicate. (#8)
- `toContainOnly` for checking that every element in an array is equal to a given value, or matches a given predicate. (#8)

### Changed
- `toSatisfy`, `toSatisfyAll`, and `toSatisfyAny` catch anything that is thrown while evaluating their predicates and throw a `FailingExpectationException` showing the original exception (or error) message. This is also true of their negated counterparts. (#19)
- `toThrow` now prints the received throwable's message and stacktrace if it's not the expected type of throwable. (#21)

---

## [0.5.0] · 2021-04-25

### Changed
- Updated `toApproximatelyEqual` to use `std.math.isClose` instead of the deprecated `std.math.approxEqual`. (#12)
- Code excerpts are now loaded from source files only when an expectation fails, and not at compile time for every expectation. This means `stringImportPaths "."` and `dflags "-J."` are no longer needed in the project's dub configuration file. (#15)
- Moved the logic for negated expecations to their own struct. (#16)
- Renamed struct `Expectation` to `Expect`.
- Split `EEException` into two different exceptions. `FailingExpectationException` is thrown upon regular test failures, and `InvalidExpectationException` is thrown when an expectation wasn't constructed properly. (#4)
- When printing source code snippets, lines longer than 120 characters are truncated. (#7)
- `toBeOfType` now shows the received type, rather than the received value.
- Negated expectations' failure messages now say "Forbidden" instead of "Expected".
- Failure messages no longer color the received/expected values, and instead color the actual words "Received" and "Expected".
- `toBeOfType` and `toThrow` will now print an inheritance tree of the received value (or thrown exception) upon failure.
- Tweaked some failure messages for consistency and readability.

### Fixed
- Source code indented with tabs now has its tabs converted to spaces when showing source code snippets. Previously, the tab itself would be printed which sometimes resulted in odd formatting. (#2)

### Docs
- Improved wording in doc comments.

---

## [0.4.2] · 2021-04-18

### Docs
- Use full URL for images in the readme so that they show up correctly on the dub website.
- Add forgotten sections to changelog (v0.4.0 and v0.4.1).

---

## [0.4.1] · 2021-04-15

### Docs
- Add `dub.json` formatted code to the readme.
- Improve `toSatisfy___` example in the readme to demonstrate all three variants of that function.

---

## [0.4.0] · 2021-04-11

### Added
- `toThrow` method for checking that a block of code throws a certain exception. (#9)

### Changed
- The library is now split up into a few different packages. The old import still works, but only imports `expect` and `Expectation` (which should be the only things of interest for now, anyway).

### Fixed
- This library's dependency on "silly" should no longer interfere with users' own dependencies on silly. (#11)

### Docs
- Add screenshots to the readme showing what a failing test outputs and demonstrating the IDE autocompletion works.
- Add section to the readme explaining why exceeds-expectations was created.
- Add links to GitLab, GitHub, and Dub at the top of the readme.

---

## [0.3.0] · 2021-02-28

### Changed
- Strings are now enclosed by double quotes in order to improve readability of empty strings and multiline strings.

### Fixed
- The documentation of `toBeOfType` now correctly refers to `TExpected` instead of `TActual`.

---

## [0.2.0] · 2020-12-06

### Added
- Throws an exception if `expect` was called but no assertion was made.

---

## [0.1.1] · 2020-12-05

### Fixed
- `toBe` is now legal iff `received `**`is`**` expected` is legal.

---

## [0.1.0] · 2020-11-22

### Added:
- `expect` function for starting a chain of assertions
- `toEqual` method for comparing equality
- `toBe` method for comparing identity
- `toApproximatelyEqual` method for floating-point comparisons
- `toSatisfy`, `toSatisfyAny`, and `toSatisfyAll` methods for checking against predicate functions



[0.1.0]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.1.0
[0.1.1]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.1.1
[0.2.0]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.2.0
[0.3.0]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.3.0
[0.4.0]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.4.0
[0.4.1]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.4.1
[0.4.2]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.4.2
[0.5.0]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.5.0
[0.6.0]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.6.0
[0.7.0]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.7.0
[0.7.1]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.7.1
[0.8.0]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.8.0
[0.9.0]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.9.0
[0.9.1]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.9.1
[0.9.2]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.9.2
[0.9.3]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.9.3
[0.9.4]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.9.4
[0.9.5]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.9.5
[0.9.6]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.9.6
