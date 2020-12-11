//
//  Board.swift
//  ChessApp
//
//  Created by Vlad Bilyk on 03.12.2020.
//  Copyright © 2020 Vlad Bilyk. All rights reserved.
//

import Foundation


public class Board {
    
    public static let MAXROW: Int = 7
    
//    var pieces: [Piece] = []
    var squares: [[Square]] = []
    var whiteKing: King? = nil
    var blackKing: King? = nil
    
    init() {
        fillBoardWithEmptySquares()
        fillBoardWithPieces()
    }
    
    // MARK: - Setup
    
    private func fillBoardWithEmptySquares() {
        for rowIndex in 0...Board.MAXROW {
            var squaresRow = [Square]()
            
            for colIndex in 0...Board.MAXROW {
                squaresRow.append(Square(coordinates: [rowIndex, colIndex], piece: nil))
            }
            
            self.squares.append(squaresRow)
        }
    }
    
    private func fillBoardWithPieces() {
        var isWhite = false
        
        var row = 1
        // for each colour, black are first
        for _ in 1...2 {
            
            // create pawns
            for iPawn in 1...8 {
                let col = iPawn - 1
                self.squares[row][col].piece = Pawn(isWhite: isWhite)
            }
            
            //change row
            row = isWhite ? 7 : 0
            
            //create rooks, knights and bishops
            for j in 0...1 {
                let rookCols = [0, 7]
                let knightCols = [1, 6]
                let bishopCols = [2, 5]
                self.squares[row][rookCols[j]].piece = Rook(isWhite: isWhite)
                self.squares[row][knightCols[j]].piece = Knight(isWhite: isWhite)
                self.squares[row][bishopCols[j]].piece = Bishop(isWhite: isWhite)
            }
            
            //create queen and king
            self.squares[row][3].piece = Queen(isWhite: isWhite)
            
            if isWhite {
                self.whiteKing = King(isWhite: isWhite)
                self.squares[row][4].piece = self.whiteKing
            } else {
                self.blackKing = King(isWhite: isWhite)
                self.squares[row][4].piece = self.blackKing
            }
            
            
            //change settings for white pieces
            row = 6
            isWhite = true
        }
    }
    
    // MARK: - Moving Logic
    
    func movePiece(from fromSquare: Square, to toSquare: Square) {
        if fromSquare.isEmpty {
            return
        }
        if self.isValidMove(from: fromSquare, to: toSquare) {
            toSquare.removePiece()
            toSquare.piece = fromSquare.piece
            fromSquare.removePiece()
        }
        
    }
    
    func isValidMove(from fromSquare: Square, to toSquare: Square) -> Bool {
                
        let fromPiece = fromSquare.piece!
        
        // 1) Check if this piece can move like that
        if !fromPiece.isPossibleMove(toCoordinates: toSquare.coordinates) {
            return false
        }
        
        // 2) TODO: Check if the King is under check
        if kingUnderCheck(isWhite: fromPiece.isWhite) {
            // TODO: check if this move protects the king
        }
        
        // 3) Check the toSquare
            // contains a piece of the same color: return
            // contains a piece of different color: continue
            // TODO: isEmpty: continue
        if !toSquare.isEmpty {
            let toPiece = toSquare.piece!
            if toPiece.equalColor(fromPiece) {
                return false
            }
            // TODO: Check if this move puts the King of fromPiece.color under check
        }
        
        return true
    }
    
    func kingUnderCheck(isWhite: Bool) -> Bool {
        if isWhite {
            return self.whiteKing!.underCheck
        }
        return self.blackKing!.underCheck
    }
    
    
}
