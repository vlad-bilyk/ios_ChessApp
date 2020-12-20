//
//  BoardView.swift
//  ChessApp
//
//  Created by Vlad Bilyk on 11.12.2020.
//  Copyright © 2020 Vlad Bilyk. All rights reserved.
//

import UIKit

class BoardView: UIView {
    
    private var board: Board?
    private var squareViews: [[SquareView]] = []
    private var lastHighlightedSquareView: SquareView?

    lazy var squareSide: CGFloat = {
        return self.frame.height / 8
    }()
        
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.drawSquares()
    }
    
    func drawSquares() {
        guard let _ = self.board else { return }
        
        self.squareSide = self.frame.height / 8
        
        for row in self.board!.squares {
            var views: [SquareView] = []
            for square in row {
                let squareRect = CGRect(x: self.squareSide * CGFloat(square.coordinates.col), y: self.squareSide * CGFloat(square.coordinates.row), width: self.squareSide, height: self.squareSide)
                let squareView = SquareView(frame: squareRect)
                squareView.setSquare(square: square)
                self.addSubview(squareView)
                views.append(squareView)
            }
            self.squareViews.append(views)
        }
        
    }
    
    public func setBoard(board: Board) {
        self.board = board
    }

}


extension BoardView {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchPos = touch.location(in: self)
            let row = Int(floor(touchPos.y / self.squareSide))
            let col = Int(floor(touchPos.x / self.squareSide))
            
            let touchedSquareView = self.squareViews[row][col]
            
            // turn off the last highlighted square,
            // but if the same square is clicked multiple times in a row - don't do anything
            if let last = self.lastHighlightedSquareView {
                if last != touchedSquareView {
                    last.highlightOff()
                }
            }
            
            self.lastHighlightedSquareView = touchedSquareView.switchHighlight()
        }
        
    }
    
}
