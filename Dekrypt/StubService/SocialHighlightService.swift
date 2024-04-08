//
//  SocialHighlightService.swift
//  DekryptUI_Example
//
//  Created by Krishna Venkatramani on 04/02/2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import Combine
import DekryptUI
import DekryptService

public class StubSocialHighlightService: SocialHighlightServiceInterface {
    
    public init() {}
    
    public func fetchSocialSentiment(section: String) -> GenericResultPublisher<SentimentForTicker> {
        .just(.init(data: nil, success: false, err: nil))
    }
    
    public func fetchSocialSentimentForTickers(tickers: [String]) -> GenericResultPublisher<SentimentForTickers> {
        .just(.init(data: nil, success: false, err: nil))
    }
    
    public func fetchInsightDigest(page: Int, limit: Int) -> GenericResultPublisher<[InsightDigestModel]> {
        .just(.init(data: nil, success: false, err: nil))
    }
    
    
    public func fetchSocialHighlight(refresh: Bool) -> AnyPublisher<SocialHighlightResult, Error> {
        Bundle.main.loadDataFromBundle(name: "socialHighlights", extensionStr: "json")
    }
    
}
