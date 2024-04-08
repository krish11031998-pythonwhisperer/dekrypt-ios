//
//  NewsStubService.swift
//  DekryptUI
//
//  Created by Krishna Venkatramani on 03/02/2024.
//

import Foundation
import Combine
import DekryptUI
import DekryptService

private let dataBundle: Bundle = {
    Bundle(identifier: "org.cocoapods.DekryptUI")!
}()

public class StubNewsService: NewsServiceInterface {
    
    public init() {}
    
    public func fetchNewsForAllTickers(entity: [String]?, items: String?, source: String?, page: Int, limit: Int, refresh: Bool) -> AnyPublisher<NewsResult, Error> {
        Bundle.main.loadDataFromBundle(name: "news", extensionStr: "json")
    }
    
    public func fetchNewsForEvent(eventId: String, refresh: Bool) -> AnyPublisher<NewsResult, Error> {
        Bundle.main.loadDataFromBundle(name: "news", extensionStr: "json")
    }
    
    public func fetchNewsForHeadlines(newsID: String) -> AnyPublisher<NewsResult, Error> {
        Bundle.main.loadDataFromBundle(name: "news", extensionStr: "json")
    }
    
    public func newsSearch(query: String, page: Int, limit: Int, refresh: Bool, topic: String?) -> AnyPublisher<NewsResult, Error> {
        Bundle.main.loadDataFromBundle(name: "news", extensionStr: "json")
    }
    
    public func fetchMainNewsSection(topics: [String], refresh: Bool) -> AnyPublisher<GenericResult<[String : [NewsModel]]>, Error> {
//        Bundle.main.loadDataFromBundle(name: "news", extensionStr: "json")
        .just(.init(data: nil, success: false, err: nil))
    }
    
    public func fetchTrendingNews(refresh: Bool) -> AnyPublisher<GenericResult<[TrendingHeadlinesModel]>, Error> {
        Bundle.main.loadDataFromBundle(name: "news", extensionStr: "json")
    }
    
    public func fetchRankedNews(page: Int, limit: Int, refresh: Bool) -> AnyPublisher<NewsResult, Error> {
        Bundle.main.loadDataFromBundle(name: "news", extensionStr: "json")
    }
    
    public func fetchGeneralNews(page: Int, limit: Int, refresh: Bool) -> AnyPublisher<NewsResult, Error> {
        Bundle.main.loadDataFromBundle(name: "news", extensionStr: "json")
    }
    
    
}
