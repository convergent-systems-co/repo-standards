# Add unit test for token exchange

Add a test in `auth/google_oauth_test.go` covering the token-exchange step:
- valid code → expected token response
- invalid code → returns ErrInvalidGrant
- network error → returns ErrUpstream

Mock the Google endpoint with `httptest.NewServer`.
