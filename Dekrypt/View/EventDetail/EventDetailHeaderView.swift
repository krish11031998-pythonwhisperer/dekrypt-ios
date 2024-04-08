//
//  EventDetailHeaderView.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 13/02/2024.
//

import UIKit
import KKit
import Combine
import DekryptUI
import DekryptService

class EventDetailViewHeader: ConfigurableUIView {
    
    struct Model: Hashable, ActionProvider {
        let event: EventModel
        public var action: Callback?
        
        init(event: EventModel, action: Callback? = nil) {
            self.event = event
            self.action = action
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.event == rhs.event
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(event)
        }
    }
    
//MARK: - Properties
    private lazy var eventHeader: UILabel = { .init() }()
    private lazy var eventDescription: UILabel = { .init() }()
    private var bag: Set<AnyCancellable> = .init()
    
//MARK: - Constructors
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
//MARK: - Protected Methods
    
    private func setupView() {
        let mainStack: UIStackView = .VStack(subViews: [eventHeader, eventDescription], spacing: 12, alignment: .leading)
        eventHeader.numberOfLines = 0
        eventDescription.numberOfLines = 0
        addSubview(mainStack)
        setFittingConstraints(childView: mainStack, insets: .init(vertical: 0, horizontal: .appHorizontalPadding))
        backgroundColor = .surfaceBackground
    }
    
//MARK: - Exposed Methods
    
    public func configure(with model: Model) {
        model.event.eventName.heading1().render(target: eventHeader)
        model.event.eventText?.body2Medium().render(target: eventDescription)
    }
}

