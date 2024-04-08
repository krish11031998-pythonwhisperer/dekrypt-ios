//
//  SearchHeader.swift
//  Dekrypt
//
//  Created by Krishna Venkatramani on 08/04/2024.
//

import UIKit
import KKit
import DekryptService
import DekryptUI
import Combine

class SearchHeader: UIView {
    
    private lazy var stack: UIStackView = .VStack(spacing: .appVerticalPadding.half,
                                                  insetFromSafeArea: false)
    private lazy var textField: CustomTextField = .init()
    private lazy var headerLabel: UILabel = .init()
    private weak var onSearch: PassthroughSubject<String?, Never>?
    private let headerTitle: String
    private var bag: Set<AnyCancellable> = .init()
    
    init(placeHolder: String, header: String, onSearch: PassthroughSubject<String?, Never>) {
        self.headerTitle = header
        self.onSearch = onSearch
        super.init(frame: .zero)
        self.textField.placeholder = placeHolder
        setupView()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        [headerLabel, textField].addToView(stack)
        headerTitle.styled(font: CustomFonts.semibold, color: .textColor, size: 24).render(target: headerLabel)
        textField.setHeight(height: 44)
        textField.returnKeyType = .search
        
        addSubview(stack)
      
        stack.fillSuperview(inset: .init(vertical: .zero, horizontal: .appHorizontalPadding))
        
        backgroundColor = .surfaceBackground
    }
    
    private func bind() {
        textField.publisher(for: .editingDidEndOnExit)
            .withUnretained(self)
            .sinkReceive { (header, event) in
                header.onSearch?.send(header.textField.text)
                if let text = header.textField.text {
                    TickerUserDefaultService.shared.addRecentlySearchedTicker(ticker: text)
                }
            }
            .store(in: &bag)
    }
}

