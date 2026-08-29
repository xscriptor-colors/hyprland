// Temporary test shell — loads ONLY the new Dock so we can validate the
// position-agnostic bar in isolation, without touching the live TopBar.
// Remove once the migration is complete.
import QtQuick
import Quickshell
import "dock"

ShellRoot {
    Dock {}
}
