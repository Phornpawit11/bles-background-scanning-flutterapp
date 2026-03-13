CRITICAL CODING STANDARDS & UI RULES:
Act as a Senior Flutter Developer. Every piece of code you write MUST adhere strictly to the following Clean Code principles:

1. **Strictly No UI Deep Nesting (Avoid Pyramid of Doom):**
   - The `build` method of any screen MUST NOT exceed 50-60 lines.
   - You MUST proactively split the UI into smaller, logical components.

2. **Always Use StatelessWidgets for Split UI:**
   - When extracting UI parts, DO NOT use helper methods that return a `Widget` (e.g., `Widget _buildButton() { ... }`).
   - Instead, extract them into separate private or public `StatelessWidget` classes (e.g., `class _CustomButton extends StatelessWidget { ... }`). This is crucial for Flutter's rendering performance.

3. **Separation of Concerns (GetX Pattern):**
   - Views should ONLY contain UI code.
   - All business logic, variables, state, and API calls MUST reside in the GetX Controller.
   - Use `Obx()` only on the smallest possible widget that needs to rebuild, not wrapping the entire screen.

4. **Clean Code & Readability:**
   - Use descriptive and meaningful variable/method names.
   - Add concise comments above complex logic blocks or background task initializations.
   - Remove boilerplate or redundant code.

If you generate code that has a single massive `build` method, I will ask you to rewrite it. Please acknowledge these rules before providing the code.
