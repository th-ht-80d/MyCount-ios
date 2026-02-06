//
//  CountdownImageSample.swift
//  MyCount
//
//  Created by Codex on 2025/02/05.
//

import Foundation

struct CountdownImageSample: Identifiable, Hashable {
    let id: String
    let label: String
    let assetName: String
}

enum CountdownImageSamples {
    static let samples: [CountdownImageSample] = [
        CountdownImageSample(id: "birthday", label: "誕生日", assetName: "happy_birthday"),
        CountdownImageSample(id: "anniversary", label: "記念日", assetName: "anniversary"),
        CountdownImageSample(id: "sunset", label: "夕焼け", assetName: "image_sample")
    ]

    static var `default`: CountdownImageSample {
        samples.first ?? CountdownImageSample(id: "default", label: "サンプル", assetName: "image_sample")
    }

    static func find(id: String) -> CountdownImageSample {
        samples.first { $0.id == id } ?? `default`
    }
}
