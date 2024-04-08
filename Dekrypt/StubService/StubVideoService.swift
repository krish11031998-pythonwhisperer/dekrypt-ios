//
//  StubVideoService.swift
//  DekryptUI_Example
//
//  Created by Krishna Venkatramani on 04/02/2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Combine
import DekryptUI
import DekryptService
import Foundation

public class StubVideoService: VideoServiceInterface {
    
    public init() {}
    
    public func fetchVideo(entity: [String]?, page: Int, limit: Int) -> AnyPublisher<VideoResult, Error> {
        Bundle.main.loadDataFromBundle(name: "videos", extensionStr: "json")
    }
    
}
