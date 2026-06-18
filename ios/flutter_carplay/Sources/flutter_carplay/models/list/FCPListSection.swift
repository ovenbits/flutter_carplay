//
//  FCPListSection.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPListSection {
  private(set) var _super: CPListSection?
  private(set) var elementId: String
  private var header: String?
  private var items: [CPListTemplateItem]
  private var objcItems: [FCPListTemplateItem]
  private var sectionIndexEnabled: Bool
  private var sharedLeadingImage: String?
  private var deferSharedLeadingImage: Bool
  private var deferredSharedLeadingImageCancelled = false

  init(obj: [String: Any]) {
    self.elementId = obj["_elementId"] as! String
    self.header = obj["header"] as? String
    self.sectionIndexEnabled = obj["sectionIndexEnabled"] as? Bool ?? true
    let parsedSharedLeadingImage = obj["sharedLeadingImage"] as? String
    let parsedDeferSharedLeadingImage =
      obj["deferSharedLeadingImage"] as? Bool ?? (parsedSharedLeadingImage != nil)
    self.sharedLeadingImage = parsedSharedLeadingImage
    self.deferSharedLeadingImage = parsedDeferSharedLeadingImage
    self.objcItems = (obj["items"] as! [[String: Any]]).map { dict -> FCPListTemplateItem in
      guard let runtimeType = dict["runtimeType"] as? String else {
        fatalError("FCPListSection.init: Missing runtimeType in item")
      }

      if runtimeType == "FCPListImageRowItem" {
        return FCPListImageRowItem(obj: dict) as FCPListTemplateItem
      } else if runtimeType == "FCPListItem" {
        return FCPListItem(
          obj: dict,
          sectionSharedLeadingImage: parsedSharedLeadingImage,
          sectionDeferSharedLeadingImage: parsedDeferSharedLeadingImage
        ) as FCPListTemplateItem
      } else {
        fatalError("FCPListSection.init: Unknown item runtimeType: \(runtimeType)")
      }
    }
    self.items = self.objcItems.map {
      $0.get
    }
  }

  var get: CPListSection {
    let sectionIndexTitle = sectionIndexEnabled ? header : nil

    let listSection = CPListSection.init(
      items: items, header: header, sectionIndexTitle: sectionIndexTitle)

    self._super = listSection
    return listSection
  }

  public func getFCPListTemplateItems() -> [FCPListTemplateItem] {
    return objcItems
  }

  public func cancelDeferredSharedLeadingImage() {
    deferredSharedLeadingImageCancelled = true
  }

  /// Applies [sharedLeadingImage] to inheriting rows that still show the grey
  /// placeholder after push, in native batches.
  public func applyDeferredSharedLeadingImage() {
    guard deferSharedLeadingImage, let imageKey = sharedLeadingImage else { return }
    applySharedLeadingImageToInheritingRows(imageKey: imageKey)
  }

  /// True when [sharedLeadingImage] is already in the native pre-warm cache.
  public func hasPreloadedSharedLeadingImage() -> Bool {
    guard let imageKey = sharedLeadingImage else { return false }
    return imagePrewarmCache.object(forKey: imageKey as NSString) != nil
  }

  private func applySharedLeadingImageToInheritingRows(imageKey: String) {
    guard !deferredSharedLeadingImageCancelled else { return }

    var listItems: [FCPListItem] = []
    listItems.reserveCapacity(objcItems.count)
    for case let item as FCPListItem in objcItems
    where item.currentLeadingImageKey == FCPListItem.deferredLeadingPlaceholderImageKey {
      listItems.append(item)
    }
    guard !listItems.isEmpty else { return }

    let applyToItems: (UIImage) -> Void = { uiImage in
      var index = 0
      let batchSize = 20

      func applyBatch() {
        guard !self.deferredSharedLeadingImageCancelled else { return }

        let end = min(index + batchSize, listItems.count)
        while index < end {
          if self.deferredSharedLeadingImageCancelled { return }
          listItems[index].applyLeadingImage(uiImage, imageKey: imageKey)
          index += 1
        }
        if index < listItems.count {
          DispatchQueue.main.async { applyBatch() }
        }
      }

      applyBatch()
    }

    if let cachedImage = imagePrewarmCache.object(forKey: imageKey as NSString) {
      applyToItems(cachedImage)
      return
    }

    loadUIImage(from: imageKey, bytes: nil, tint: nil) { uiImage in
      guard !self.deferredSharedLeadingImageCancelled else { return }
      applyToItems(uiImage)
    }
  }
}
