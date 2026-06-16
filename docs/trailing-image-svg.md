# Using SVG as a Trailing Image on CarPlay List Rows

> **Requires `flutter_carplay` 1.4.0+** (included in the `sync/upstream-1.6.1-plus-fork-patches` branch).
> The old 1.3.3 fork only had `accessoryImage` / `setAccessoryImage` — no `trailingImage` or `setTrailingImageTint`.

Use `trailingImage` on `CPListItem`. It maps to CarPlay’s trailing `accessoryImage` on the native side. SVG works the same as the leading `image`: pass a Flutter asset path ending in `.svg`.

## 1. Declare the asset

In your **app’s** `pubspec.yaml` (not the plugin):

```yaml
flutter:
  assets:
    - assets/carplay/icons/
```

## 2. Set it when creating the row

```dart
CPListItem(
  text: 'Episode title',
  detailText: '12 min left',
  image: 'assets/carplay/show_artwork.png',       // leading (left)
  trailingImage: 'assets/carplay/icons/play.svg', // trailing (right)
  trailingImageTint: const AutoImageTint.platform(),
  onPress: (complete, self) async {
    complete();
  },
)
```

Typical split:

- **`image`** — show/episode artwork (left)
- **`trailingImage`** — state icon such as play, pause, downloaded, explicit (right)

## 3. Update it at runtime

```dart
// Switch trailing icon when playback starts (optional tint in same call)
item.setTrailingImage(
  'assets/carplay/icons/pause.svg',
  imageTint: const AutoImageTint.platform(),
);

// Or update tint only, without changing the image path
item.setTrailingImageTint(const AutoImageTint.primary());
```

`setTrailingImage()` and `setTrailingImageTint()` both trigger a native `updateCPListItem` call. The SVG is rasterized to PNG automatically on each push/update.

## 4. Optional tint

Trailing SVGs support the same tint API as leading images:

```dart
trailingImageTint: const AutoImageTint.primary(),

// or a custom color
trailingImageTint: AutoImageTint.custom(
  color: UIColor(red: 255, green: 255, blue: 255),
),
```

`AutoImageTint.platform()` is usually best for icons that must stay visible on focused or selected rows.

## 5. Optional raster size

If the icon looks soft or too large, adjust the global raster size before pushing or updating templates:

```dart
FlutterCarplay.svgRasterSize = 48; // default is 120
```

## Supported formats

| Format                                | Trailing image |
| ------------------------------------- | -------------- |
| Flutter asset `assets/icons/play.svg` | Yes            |
| Flutter asset PNG/JPG                 | Yes            |
| `file:///path/to/image.png`           | Yes            |
| `https://example.com/image.png`       | Yes            |
| `https://example.com/icon.svg`        | No             |
| `file:///path/to/icon.svg`            | No             |

Only **local Flutter asset** SVGs are rasterized. Remote and `file://` SVG paths are not supported.

## Important rules

| Do                                          | Don’t                                                                                                                 |
| ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Use `trailingImage` for the right-side icon | Use `accessoryImage` in new code (legacy)                                                                             |
| Use `trailingImage` for custom icons        | Set `accessoryType` chevron **and** `trailingImage` — the image wins; chevron is ignored when a trailing image is set |

When `trailingImage` (or `accessoryImage`) is set, CarPlay shows that image on the right instead of a system chevron or disclosure indicator.

## Full list example

```dart
CPListTemplate(
  title: 'Episodes',
  sections: [
    CPListSection(
      header: 'Today',
      items: episodes.map((ep) => CPListItem(
        text: ep.title,
        detailText: ep.duration,
        image: ep.artworkPath, // file:// or asset PNG
        trailingImage: ep.isPlaying
            ? 'assets/carplay/icons/pause.svg'
            : 'assets/carplay/icons/play.svg',
        trailingImageTint: const AutoImageTint.platform(),
        isPlaying: ep.isPlaying,
        onPress: (complete, self) async {
          self.setTrailingImage(
            ep.isPlaying
                ? 'assets/carplay/icons/pause.svg'
                : 'assets/carplay/icons/play.svg',
          );
          complete();
        },
      )).toList(),
    ),
  ],
)
```

## Android Auto

`trailingImage` is **CarPlay only** (`CPListItem`).

On Android Auto, list rows use `AAListItem.imageUrl` for a single row image. There is no separate trailing-image field on AA list rows today.

## Related

- [Flutter Asset SVG Images](../README.md#flutter-asset-svg-images) — all image fields that support SVG
- `lib/models/list/list_item.dart` — `CPListItem` API
- `lib/helpers/svg_rasterizer.dart` — rasterization and payload walker
