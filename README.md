# ExAws.SES

[![Module Version](https://img.shields.io/hexpm/v/ex_aws_ses.svg)](https://hex.pm/packages/ex_aws_ses)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_aws_ses/)
[![Total Download](https://img.shields.io/hexpm/dt/ex_aws_ses.svg)](https://hex.pm/packages/ex_aws_ses)
[![License](https://img.shields.io/hexpm/l/ex_aws_ses.svg)](https://github.com/ex-aws/ex_aws_ses/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/ex-aws/ex_aws_ses.svg)](https://github.com/ex-aws/ex_aws_ses/commits/master)

Service module for [https://github.com/ex-aws/ex_aws](https://github.com/ex-aws/ex_aws).

## Installation

The package can be installed by adding `:ex_aws_ses` to your list of dependencies in `mix.exs`
along with `:ex_aws` and your preferred JSON codec / HTTP client

```elixir
def deps do
  [
    {:ex_aws, "~> 2.0"},
    {:ex_aws_ses, "~> 2.0"},
    {:poison, "~> 3.0"},
    {:hackney, "~> 1.9"},
  ]
end
```

Documentation can be found at [https://hexdocs.pm/ex_aws_ses](https://hexdocs.pm/ex_aws_ses).

## License

The MIT License (MIT)

Copyright (c) 2014 CargoSense, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
