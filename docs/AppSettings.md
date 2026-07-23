# App Settings

- App settings are injected into the environment as an `.environmentObject`.

## Themes
- There is a list of themes within the app settings.
- Each theme is manual at the moment with 3 colours (for debugging).
  - Default themes are always present in the theme picker, not saved anywhere, hard-coded.
  - Custom themes can be made (later), and will be saved separately, custom-encoded to make sure they're encodable.

## Functions

`getUserThemesFromStorage() -> // TODO`
- Retrieves stored user themes, in the format TBD.
