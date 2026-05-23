# Code review finding: missing null check in user.go:42

While reviewing PR #347 I noticed that `GetUserByID` dereferences the result
of the DB lookup without checking the error return. If the DB call fails the
process panics. This is in `internal/users/user.go:42`.

Not blocking PR #347 (different scope) but should be tracked.
