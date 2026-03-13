Act as a Senior Flutter UI/UX Developer. Please redesign my current BLE scanning app UI to be "Modern, Minimal, Professional, and Clean".

### Key Features to Redesign:

1.  **Scanning State (App Bar):** Replace the standard scanning indicator with a "Soft Pulse" animation integrated around the App Bar title or a simple, elegant "Searching..." text that gently fades in and out.
2.  **Device Cards (The Main Focus):** Instead of standard ListTile, use plain, solid white `#FFFFFF` cards with generous padding (`20+`) and very softly rounded corners (`borderRadius: 16`).
3.  **Soft Shadows:** Do NOT use Glassmorphism (no blurs or opacities). Instead, use a very subtle, diffused drop shadow on the white cards.
    - Use: `BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: Offset(0, 4))` to make the cards appear to "float" gently above the background.
4.  **Layout Priority:** Make the device name (`PB713-XXXX`) bold and large (e.g., `18sp`). Place the UUID/Major/Minor details on secondary lines with a lighter, gray font (`Colors.grey[600]`).
5.  **Status Badges:** Design a small, clean "chip" or badge to show:
    - **Battery:** Icon + percentage with a dynamic color (`# Success` for high, `# Warning` for medium, `# Critical` for low).
    - **Status:** A green dot for "Connectable" or "Ready" and a gray dot for "Out of Range".

### Design Principles:

- **Color Palette:** Pure White (`#FFFFFF`) for cards. Very Light Gray (`#F6F8FB`) for the screen background. Primary color: A single professional color like Midnight Blue (`#102A43`) or Clean Indigo (`#3F51B5`).
- **Whitespace:** Use generous spacing between cards and elements inside the cards to reduce cognitive load.
- **Micro-Interactions:** Add a very subtle scale-down animation (`transform: scale(0.98)`) when a card is tapped.

### Code Style:

- Provide the full Flutter code, separating the `DeviceListScreen` and a stateless `DeviceCard` widget.
- Use GoogleFonts (e.g., 'Google Sans' or 'Inter') for a clean typography feel.
