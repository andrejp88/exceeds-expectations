# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Changed
- Updated `toApproximatelyEqual` to use `std.math.isClose` instead of the deprecated `std.math.approxEqual`.
- Code excerpts are now loaded from source files only when an expectation fails, and not at compile time for every expectation. This means `stringImportPaths "."` and `dflags "-J."` are no longer needed in the project's dub configuration file.
- Moved the logic for negated expecations to their own struct.
- Renamed struct `Expectation` to `Expect`.
- Split `EEException` into two different exceptions. `FailingExpectationException` is thrown upon regular test failures, and `InvalidExpectationException` is thrown when an expectation wasn't constructed properly.

### Fixed
- Source code indented with tabs now has its tabs converted to spaces when showing source code snippets. Previously, the tab itself would be printed which sometimes resulted in odd formatting.


## [0.4.2] · 2021-04-18

### Docs
- Use full URL for images in the readme so that they show up correctly on the dub website.
- Add forgotten sections to changelog (v0.4.0 and v0.4.1).


## [0.4.1] · 2021-04-15

### Docs
- Add `dub.json` formatted code to the readme.
- Improve `toSatisfy___` example in the readme to demonstrate all three variants of that function.


## [0.4.0] · 2021-04-11

### Added
- `toThrow` method for checking that a block of code throws a certain exception.

### Changed
- The library is now split up into a few different packages. The old import still works, but only imports `expect` and `Expectation` (which should be the only things of interest for now, anyway).

### Fixed
- This library's dependency on "silly" should no longer interfere with users' own dependencies on silly.

### Docs
- Add screenshots to the readme showing what a failing test outputs and demonstrating the IDE autocompletion works.
- Add section to the readme explaining why exceeds-expectations was created.
- Add links to GitLab, GitHub, and Dub at the top of the readme.


## [0.3.0] · 2021-02-28

### Changed
- Strings are now enclosed by double quotes in order to improve readability of empty strings and multi-line strings.

### Fixed
- The documentation of `toBeOfType` now correctly refers to `TExpected` instead of `TActual`.


## [0.2.0] · 2020-12-06

### Added
- Throws an exception if `expect` was called but no assertion was made.


## [0.1.1] · 2020-12-05

### Fixed
- `toBe` is now legal iff `received `**`is`**` expected` is legal.


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
