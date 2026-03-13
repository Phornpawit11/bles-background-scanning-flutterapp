Act as an expert Flutter Developer. I have a monolithic UI screen that I want to refactor into smaller, reusable "Dumb Widgets" and then showcase them using `widgetbook` (code generation approach).

Please perform the following tasks:

1. Widget Extraction & Decoupling:
   - Analyze the provided code and extract distinct UI components into separate, stateless classes.
   - Ensure they are "Dumb Widgets"—remove all direct references to controllers (GetX/Bloc), global states, or API calls.
   - SPECIAL HANDLING FOR TRANSLATIONS: Remove all localization/internationalization calls (e.g., `.tr`). Replace them with `String` parameters in the constructor. The translation logic must happen at the parent/caller level, not inside the Dumb Widget.
   - Use constructor parameters for data and callbacks (e.g., `VoidCallback`, `Function(String)`) for actions.

2. Widgetbook UseCase Implementation:
   - For each extracted widget, create a `@widgetbook.UseCase` function.
   - Use `context.knobs` (string, boolean, number, options) to make the widget properties interactive in the Widgetbook UI.
   - Organize them into logical categories (e.g., 'Components/Cards', 'Components/Buttons').
   - For parameters that replaced `.tr`, use `context.knobs.string` to allow testing different languages or long strings.

3. Code Generation & Setup:
   - Provide the code for the main Widgetbook entry point (e.g., `lib/widgetbook.dart`) with the `@widgetbook.App` annotation.
   - List the terminal commands for adding dependencies and running the `build_runner`.

CRITICAL: All explanations, logic reasoning, and code comments MUST be in THAI.

Here is the monolithic UI code I want to refactor:
[... วางโค้ดหน้า UI หลักของคุณที่นี่ ...]
