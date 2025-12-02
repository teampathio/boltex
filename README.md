# Boltex

An unofficial Elixir library for building Slack apps, inspired by (but not affiliated with) Slack's official Bolt frameworks for Python and TypeScript.

## Installation

Add `boltex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:boltex, "~> 0.1.0"}
  ]
end
```

## Contributing

We use git hooks to ensure code quality. After cloning the repository and running `mix deps.get`, the hooks will be automatically installed.

The pre-commit hook runs:
- `mix format --check-formatted` - Ensures code is properly formatted
- `mix dialyzer` - Checks for type errors

If you need to bypass the hooks (not recommended), use `git commit --no-verify`.

## License

MIT License - see LICENSE file for details.

## Disclaimer

This project is not affiliated with, endorsed by, or connected to Slack Technologies. It is an independent implementation inspired by Slack's official Bolt framework concepts.
