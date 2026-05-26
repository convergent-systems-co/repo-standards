# pre-commit hook to lint markdown

Install a pre-commit hook that runs `markdownlint` on staged `.md` files and
fails the commit if lint errors are present. Should be installable via
`make install-hooks`.
