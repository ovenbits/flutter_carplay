import 'package:uuid/uuid.dart';

import 'list_template_item.dart';

/// A container that groups your list items into sections.
/// https://developer.apple.com/documentation/carplay/cplistsection
/// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
class CPListSection {
  /// Unique id of the object.
  final String _elementId;

  /// The section’s header text.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final String? header;

  /// The section’s index title.
  /// Defaults to true.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final bool? sectionIndexEnabled;

  /// The list of items for the section.
  /// iOS 12.0+ | iPadOS 12.0+ | Mac Catalyst 13.1+
  final List<CPListTemplateItem> items;

  /// When set, rows marked with [CPListItem.inheritsSectionLeadingImage] reuse this
  /// artwork once instead of repeating the URL on every item (smaller push payload).
  ///
  /// On iOS, [deferSharedLeadingImage] applies the image natively after push in
  /// batched chunks so large lists open without N synchronous `setImage` calls.
  final String? sharedLeadingImage;

  /// When true (default when [sharedLeadingImage] is set), native applies
  /// [sharedLeadingImage] after the list template is pushed.
  final bool? deferSharedLeadingImage;

  /// Creates [CPListSection] that contains zero or more list items. You can configure
  /// a section to display a header, which CarPlay displays on the trailing edge of the screen.
  CPListSection({
    this.header,
    this.sectionIndexEnabled,
    required List<CPListTemplateItem> items,
    this.sharedLeadingImage,
    this.deferSharedLeadingImage,
    String? id,
  })  : items = List<CPListTemplateItem>.from(items),
        _elementId = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        '_elementId': _elementId,
        'header': header,
        'items': items.map((e) => e.toJson()).toList(),
        'sectionIndexEnabled': sectionIndexEnabled,
        if (sharedLeadingImage != null)
          'sharedLeadingImage': sharedLeadingImage,
        if (sharedLeadingImage != null)
          'deferSharedLeadingImage': deferSharedLeadingImage ?? true,
        'runtimeType': 'FCPListSection',
      };

  String get uniqueId {
    return _elementId;
  }
}
