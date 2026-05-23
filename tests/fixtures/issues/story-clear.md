# Implement Google OAuth callback handler

The callback at `/auth/google/callback` should:
- exchange the authorization code for tokens
- fetch the user profile from Google
- create or update the local user record
- establish a session cookie
- redirect to the post-login landing page

Done when the integration test in `auth/oauth_test.go` passes against a recorded
Google response fixture.
