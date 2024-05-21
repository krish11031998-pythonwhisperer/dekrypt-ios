//
//  NewsArticleParser.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 21/05/2024.
//

import Foundation
import Combine
import SwiftSoup

public class NewsArticleParser {
    
    public static let shared: NewsArticleParser = NewsArticleParser()
    
    public enum ArticleElement {
        case text(String)
        case image(URL)
    }
    
    private func fetchArticleHTML(url: String) -> AnyPublisher<String, URLError> {
        guard let url = URL(string: url) else { return .empty(completeImmediately: true) }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .compactMap { (data, resp) in  String(data: data, encoding: .utf8) }
            .eraseToAnyPublisher()
        
    }
    
    private func parseArticleHTML(string: String) -> [ArticleElement]? {
        guard let document = try? SwiftSoup.parse(string) else { return nil }
        
        guard let body = document.body() else { return nil }
        
        var articleElements: [ArticleElement] = []
        
        guard let allElements = try? body.getAllElements() else { return nil }
        
        for element in allElements {
            guard let tagName = try? element.tagName() else { continue }
            if tagName == "p" || tagName == "span" {
                if let text = try? element.text(), !text.isEmpty {
                    articleElements.append(.text(text))
                }
            } else if tagName == "img" {
                if let src = try? element.attr("src"), let url = URL(string: src) {
                    articleElements.append(.image(url))
                }
            } else {
                print("(PARSER DEBUG) tagName: ", tagName)
            }
        }
        
        return articleElements
    }
    
    
    public func fetchArticle(urlString: String) -> AnyPublisher<[ArticleElement], URLError> {
        fetchArticleHTML(url: urlString)
            .withUnretained(self)
            .compactMap { (parser, html) in
                parser.parseArticleHTML(string: html)
            }
            .eraseToAnyPublisher()
    }
    
}
