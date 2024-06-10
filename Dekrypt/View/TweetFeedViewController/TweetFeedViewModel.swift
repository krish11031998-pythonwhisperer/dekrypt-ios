//
//  TweetFeedViewModel.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 09/06/2024.
//

import DekryptUI
import DekryptService
import KKit
import UIKit
import Combine

public class TweetFeedViewModel {
    
    struct Output {
        let section: AnyPublisher<[DiffableCollectionSection], Never>
    }
    
    @Published internal var refresh: Void = ()
    private let tweetService: TweetServiceInterface
    private let tickerName: String
    private let ticker: String
    
    init(tweetService: TweetServiceInterface, tickerName: String, ticker: String) {
        self.tweetService = tweetService
        self.tickerName = tickerName
        self.ticker = ticker
    }
    
    internal func transform() -> Output {
        let section = $refresh.setFailureType(to: Never.self).eraseToAnyPublisher()
            .withUnretained(self)
            .flatMap { (vm, _) in
                vm.tweetService.tweets(for: vm.ticker, name: vm.tickerName, refresh: true)
                    .replaceError(with: .init(data: nil, success: false, err: "No Tweets"))
                    .compactMap(\.data)
                    .eraseToAnyPublisher()
            }
            .withUnretained(self)
            .map { (vm, tweets) in
                [vm.buildTweetSection(tweets: tweets)]
            }
            .eraseToAnyPublisher()
        
        return .init(section: section)
    }
    
    private func buildTweetSection(tweets: [TweetsModel]) -> DiffableCollectionSection {
        let tweetAction: (TweetsModel) -> Callback = { [weak self] tweet in
            return {
                print("(DEBUG) clicked on tweet!")
                let urlString = "twitter://status?id=\(tweet.statusId)"
                if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
        }
        
        let tweetLinkAction: (URL) -> Void = { [weak self] url in
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        
        let cells = tweets.map { tweet in
            DiffableCollectionItem<TweetView>(.init(tweet: tweet, action: tweetAction(tweet), tweetLinkAction: tweetLinkAction)) 
        }
        let layout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0), height: .estimated(100), insets: .sectionInsets)
        return .init(0, cells: cells, sectionLayout: layout)
    }
}
