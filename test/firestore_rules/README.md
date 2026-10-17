# Firestore Rule Regression Tests

These tests run against the local Firestore emulator, never production.
They require Java, the Firebase CLI, and Node.js 22 or newer.

Install the test-only dependencies in this directory with `npm ci`.
From the repository root, run:

```powershell
firebase emulators:exec --only firestore --project demo-standin --config firebase.emulators.json "node --test --test-force-exit test/firestore_rules/rules.test.cjs"
```

Use `demo-standin`, not the production project ID. The runner loads the real
`firestore.rules` file and tests both allowed and forbidden operations.
`--test-force-exit` closes remaining Firebase client handles after all tests
and cleanup hooks have finished; failing assertions still produce a failure.

On this machine, verification used the bundled Node.js runtime:
`C:/Users/kumar/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe`.

These tests do not deploy the rules. Production deployment requires separate approval.
