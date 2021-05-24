# src https://gist.github.com/dberget/f4d157603a90cda95f289c06858dd04c
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [
    # Kernel
    inspect: 1,
    inspect: 2,

    # Tests
    assert: 1,
    assert: 2,
    assert: 3,
    on_exit: 1
  ],
  line_length: 120
]
