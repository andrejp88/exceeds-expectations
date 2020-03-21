# exceeds_expectations

exceeds_expectations is an assertions library for the D programming language.

Existing assertions libraries (such as [dshould](https://code.dlang.org/packages/dshould) and [fluent-asserts](https://code.dlang.org/packages/fluent-asserts)) rely on [unified function call syntax](https://dlang.org/spec/function.html#pseudo-member) to achieve their natural, sentence-like syntax. Unfortunately, the [D Completion Daemon](https://github.com/dlang-community/DCD) (the IDE-agnostic library responsible for code completion) [does not support auto-completions using the UFCS syntax](https://github.com/dlang-community/DCD#status). This means that IDEs cannot automatically suggest assertions for you, and it can make using UFCS-reliant libraries be annoying.

This is where exceeds-expectations comes in. Instead of assertion statements beginning with the subject, they begin with a call to `expect()`, which returns an `Expectation` object whose member functions are seen by DCD.
