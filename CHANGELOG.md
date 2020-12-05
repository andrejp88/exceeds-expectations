# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## Unreleased

- n/a

## [0.1.1] · 2020-12-05

### Fixed
- Fixed `toBe` so that it's legal iff `received is expected` is legal.


## [0.1.0] · 2020-11-22

### Added:
- `expect` function for starting a chain of assertions
- `toEqual` method for comparing equality
- `toBe` method for comparing identity
- `toApproximatelyEqual` method for floating-point comparisons
- `toSatisfy`, `toSatisfyAny`, and `toSatisfyAll` methods for checking against predicate functions

[0.1.0]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.1.0
[0.1.1]: https://gitlab.com/andrej88/exceeds-expectations/-/tree/v0.1.1
