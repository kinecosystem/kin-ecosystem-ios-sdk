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
import KinUtil

enum ImageCacheError: Error {
    case network(Error?)
    case invalidURL
    case unknwon
}

struct ImageCacheResult {
    let image: UIImage
    let cached: Bool
}

// 100mb disk cache for images

final class ImageCache {
    
    let session:URLSession
    let cache: URLCache
    
    static let shared = ImageCache()
    
    private init() {
        let config = URLSessionConfiguration.default
        cache = URLCache(memoryCapacity: 0, diskCapacity: 100 * 1024 * 1024, diskPath: "com.kin.kinfoundsation")
        config.urlCache = cache
        session = URLSession(configuration: config)
    }
    
    @discardableResult
    func image(for url: URL?) -> Promise<ImageCacheResult> {
        let p = Promise<ImageCacheResult>()
        guard let url = url else { return p.signal(ImageCacheError.invalidURL) }
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

