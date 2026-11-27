# Places

Where a session happened. The user picks a place on the tracking page, before or during a session, and manages the list in Settings. The chosen place is saved to the session's `SessionLocation.locationLabel` and stays selected for the next session, including after a relaunch.

## Sub-features

- Quick picker on the tracking page, `placePickerButton`, beside the online-friends chip. It opens a menu of `No place` plus every place shown in the picker.
- Places editor, reached from **Debug** → **Edit Places** (`editPlacesButton`). Each place is a toggle row, `placeRow_<Name>`, for whether it shows in the picker. Custom places are added with `placeNameField` and `addPlaceButton`, and can be swiped to delete. Built-ins (Home, Library, Café, Campus, Work, Transit) can only be hidden.
- The place shows on the session's row in **Sessions** and in its detail under **Location**.

## How to get to it (user POV)

The picker is on the **Focus** tab. The editor is **Debug** tab → **Edit Places**.

## Driving it with xcodebuildmcp

1. On **Focus**, press `placePickerButton`. The menu items appear in a fresh snapshot as buttons labelled with each place name. Press one; the chip's label becomes that name.
2. Start a session with `startPauseButton`. The chip stays available; pick another place to change it mid-session.
3. In the editor, press `placeNameField`, wait for `settled`, then type with `key-sequence`, and press `addPlaceButton`. A `placeRow_<Name>` row appears and the field clears.

## Proof

- After ending the session, the top row in **Sessions** shows the last place picked, and its detail's **Location** section shows it as the label.
- After a stop and relaunch, `placePickerButton` still reads the last place picked.
- A place toggled off in the editor is missing from the picker menu.

## Gotchas

- The toggle row has two switch elements: the labelled `placeRow_<Name>` and an unlabelled one just after it in the snapshot. Pressing the unlabelled one flips the toggle reliably.
- Typing straight after focusing the field can be dropped while the keyboard animates in. Wait for `settled` first, and check the field's value in a snapshot.
