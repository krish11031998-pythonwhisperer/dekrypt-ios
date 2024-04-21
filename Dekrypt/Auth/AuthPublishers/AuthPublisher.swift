//
//  AuthPublisher.swift
//  SignalMVP
//
//  Created by Krishna Venkatramani on 28/12/2022.
//

import Foundation
import Combine
import FirebaseAuth

struct AuthPublisher: Publisher {
    typealias Output = User?
    typealias Failure = Never
    
    
    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        subscriber.receive(subscription: AuthSubscription(subscriber: subscriber))
    }
    
}

class AuthSubscription<S: Subscriber>: Subscription where S.Input == User?, S.Failure == Never {
    
    private var subscriber: S?
    var currentDemand = Subscribers.Demand.none
    var handle: AuthStateDidChangeListenerHandle?
    
    init(subscriber: S) {
        self.subscriber = subscriber
        handle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self,
                  let newDemand = self.subscriber?.receive(user),
                  self.currentDemand > 0 else { return }
            self.currentDemand -= 1
            self.currentDemand += newDemand
        }
    }
    
    func request(_ demand: Subscribers.Demand) {
        currentDemand += demand
    }
    
    func cancel() {
        subscriber = nil
    }
    
    
}
