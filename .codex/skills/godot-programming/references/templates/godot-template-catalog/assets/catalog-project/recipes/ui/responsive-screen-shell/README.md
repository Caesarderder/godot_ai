# Responsive screen shell

Use for a top-level screen that must keep stable margins and switch presentation at a named
breakpoint. Child features observe `mode_changed` or read `is_narrow`; they should not inspect device
models.

The demo uses Containers and minimum sizes. Adapt safe-area margins to the actual Web host contract;
do not apply native screen-pixel insets directly to canvas units.
