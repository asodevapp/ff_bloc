# Publishing ff_bloc

## Prepare a release

1. Move the relevant `Unreleased` entries in `CHANGELOG.md` under the new
   version.
2. Update `version` in `pubspec.yaml`.
3. Run the complete validation from the repository root:

```shell
flutter pub get
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test
dart doc --dry-run
python3 -m venv build/docs-venv
build/docs-venv/bin/python -m pip install --requirement requirements-docs.txt
build/docs-venv/bin/python -m mkdocs build --strict

cd example
flutter test
cd ..

flutter pub publish --dry-run
git diff --check
```

4. Commit and push the exact release source. Publish only from a clean checkout.
5. Confirm that the account is authenticated with pub.dev and has access to the
   package publisher.

## Publish

```shell
flutter pub publish
```

## Verify from a consumer

Wait until pub.dev exposes the version, then verify the hosted package from a
separate Flutter application:

```shell
flutter pub upgrade ff_bloc
flutter analyze
flutter test
```

The consumer check matters because path dependencies and this repository's
lockfile cannot prove that the hosted package resolves correctly.
