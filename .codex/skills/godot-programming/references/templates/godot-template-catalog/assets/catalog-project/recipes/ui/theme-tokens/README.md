# Theme tokens

Use when AI needs stable semantic names for color, spacing, corners, and component variants. Components
should select `PrimaryButton` or `DangerButton`, not rebuild StyleBoxes locally.

The native factory has no ThemeGen dependency. A project may adopt ThemeGen separately after pinning
and validating the plugin, while preserving the same semantic token contract.
