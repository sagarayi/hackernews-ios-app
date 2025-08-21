//
//  Cache.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/20/25.
//

import Foundation

protocol ItemCache {
    func item(for id: Int) -> HNItem?
    func set(item: HNItem)
}

struct MemoryItemCache: ItemCache {
    final class Box: NSObject {
        let value: HNItem
        init(value: HNItem) {
            self.value = value
        }
    }
    private let cache = NSCache<NSNumber, Box>()
    
    func item(for id: Int) -> HNItem? {
        cache.object(forKey: NSNumber(value: id))?.value
    }
    
    func set(item: HNItem) {
        cache.setObject(Box(value: item), forKey: NSNumber(value: item.id))
    }
}
