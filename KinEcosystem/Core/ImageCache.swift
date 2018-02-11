//
//
//  ImageCache.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//


import Foundation
import UIKit

enum ImageCacheError: Error {
    case network(Error?)
    case invalidURL
    case unknwon
}

struct ImageCacheResult {
    let image: UIImage
    let cached: Bool
}

// lightweight 10mb in-memory cache for images

final class ImageCache {
    
    let session:URLSession
    let cache: URLCache
    
    static let shared = ImageCache()
    
    private init() {
        let config = URLSessionConfiguration.default
        cache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 0, diskPath: nil)
        config.urlCache = cache
        session = URLSession(configuration: config)
    }
    
    // memory only cache
    
    @discardableResult
    func image(for string: String) -> Promise<ImageCacheResult> {
        let p = Promise<ImageCacheResult>()
        guard let url = URL(string: string) else {
            return p.signal(ImageCacheError.invalidURL)
        }
        let request = URLRequest(url: url)
        if  let cachedResponse = cache.cachedResponse(for: request),
            let image = UIImage(data: cachedResponse.data) {
            return p.signal(ImageCacheResult(image: image, cached: true))
        }
        session.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                p.signal(ImageCacheError.network(error))
            } else if   let response = response,
                        let data = data,
                        let image = UIImage(data: data) {
                let cachedResponse = CachedURLResponse(response: response, data: data)
                self.cache.storeCachedResponse(cachedResponse, for: request)
                p.signal(ImageCacheResult(image: image, cached: false))
            } else {
                p.signal(ImageCacheError.unknwon)
            }
        }).resume()
        return p
    }
    
}
