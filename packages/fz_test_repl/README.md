# fz_test_repl

Interactive REPL for driving Flutter integration tests. Like a terminal-based Puppeteer: you type commands to tap buttons, enter text, take screenshots, and inspect the running app.

## Concepts

Instead of writing a full integration test script upfront, you start the REPL alongside your app and issue commands interactively. If the state is confusing, take a screenshot and inspect it. This is especially useful for AI-assisted development, where an AI agent can explore the app dynamically rather than predicting the exact test flow.

**Key idea**: The REPL reads from stdin, executes commands on the running Flutter app via `WidgetTester`, and prints results to stdout. The loop is: type command → see output → decide next step.

## Use cases

- **Verifying a bug fix**: Launch the app, navigate to the broken page, and assert the fix works
- **Exploring the UI structure**: `dump` to see all visible text, `screenshot` to capture state
- **AI-driven testing**: An AI agent can drive the REPL, taking screenshots when it needs visual context
- **Manual regression checks**: Quick interactive validation without writing and maintaining test scripts

## Architecture

```
User/stdin ──► TestRepl.run() ──► Command parser ──► WidgetTester action
                    │                                      │
                    │                                      ▼
                    │                              Real Flutter app
                    │                              (launched by integration_test)
                    │
                    ◄── stdout (results, errors, screenshots)
```

- **`TestRepl`** — Main REPL loop. Reads stdin, dispatches commands, handles errors.
- **`Terminal`** — ANSI-colored output helpers (`[OK]`, `[FAIL]`, `[INFO]`).
- **`integration_test` binding** — Required for `screenshot` command. Standard `flutter_test` doesn't support screenshot capture.

The package provides the REPL logic. The actual integration test entry point lives in your app's `integration_test/` directory:

```dart
// frontend/integration_test/repl_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Interactive REPL', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    await TestRepl(tester).run();
  });
}
```

## Commands

| Command | Description |
|---|---|
| `tap <text>` | Tap widget containing exact text |
| `long_press <text>` | Long-press widget containing exact text |
| `enter <label> <text>` | Enter text into a field with the given label |
| `find <text>` | Count how many widgets contain the text |
| `assert <text>` | Verify text is present on screen (green) or not (red) |
| `assert_no <text>` | Verify text is NOT present |
| `screenshot [filename]` | Save a PNG to `screenshots/` directory |
| `dump` | List all visible text widgets on screen |
| `back` | Find and tap a back button/icon |
| `wait [ms]` | Wait for given milliseconds (default 1000) |
| `settle` | Wait for all animations to complete |
| `help` | Show this command list |
| `quit` / `exit` | Exit the REPL |

Lines starting with `#` are treated as comments (ignored).

## Usage

### Prerequisites

Add to your app's `pubspec.yaml`:

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  fz_test_repl:
    path: ../from_zero_ui/packages/fz_test_repl
```

Create `integration_test/repl_test.dart` as shown above.

### Running

```bash
# Headed (requires display — you see the app window)
flutter test integration_test/repl_test.dart -d linux

# Headless (Linux, no display needed)
xvfb-run flutter test integration_test/repl_test.dart
```

### Example session

```
> dump
─── Text on screen (12 widgets) ───
  "Entidades"
  "Portcast"
  "Configuración"
  ...
─── End dump ───

> tap Entidades
[OK] Tapped "Entidades"

> find Habilitada
[INFO] No widgets found with text "Habilitada"

> wait 2000
[INFO] Waiting 2000ms...

> assert Habilitada Operaciones
[OK] "Habilitada Operaciones" is present (1 match)

> screenshot
[OK] Screenshot saved to screenshots/repl_20260716_143022.png

> quit
[INFO] Exiting REPL.
```

## Tips for CI/AI usage

- Use `# comments` to document what each command does when writing batch scripts
- Take screenshots after every major state change to build a visual log
- The REPL doesn't crash on failed commands — errors print in red and the loop continues
- `dump` + `screenshot` together give you both the text tree and the visual state
