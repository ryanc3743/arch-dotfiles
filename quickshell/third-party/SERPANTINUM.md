# Serpantinum attribution

This bar adapts the rounded dock, hover/press animation, icon loading, and
workspace occupancy patterns from ilyamiro's Serpantinum:
https://github.com/ilyamiro/serpantinum

Upstream files used:

- src/quickshell/quickactions/actions/Dock.qml
- src/quickshell/bar/modules/WorkspacesWidget.qml
- src/quickshell/bar/TopBar.qml (modular layout reference)

Modified on 2026-09-12 for this desktop: horizontal pinned dock, local settings,
Hyprland Lua actions, nine workspaces, explicit utility signals, tooltips,
and drag/drop between dock entries and workspace pills.

The adapted Quickshell bar is provided under GNU AGPL version 3; see
[license text](AGPL-3.0.md). No warranty is provided. Source is in this
quickshell directory. The upstream checkout is kept separate and unchanged.
