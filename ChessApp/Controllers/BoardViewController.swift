//
//  ViewController.swift
//  ChessApp
//
//  Created by Vlad Bilyk on 03.12.2020.
//  Copyright © 2020 Vlad Bilyk. All rights reserved.
//

import UIKit

class BoardViewController: UIViewController, Storyboarded {
    
    weak var coordinator: Coordinator?
    private var selectedSquareCoordinates: Coordinates?
    private var board: Board?
    private var gameEnded: Bool = false
    var whiteToMove: Bool = true
    var playerIsWhite: Bool = false
    
    var gameManager = GameManager.shared

    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.board = Board()
        self.board!.generate()
        
        self.boardView.setBoard(board: self.board!)
        self.view.bringSubviewToFront(self.boardView)
        
        self.messageLabel.adjustsFontSizeToFitWidth = true
        
        guard let game = self.gameManager.current else { return }
        
        if !game.started {
                self.showMessage(message: "Waiting for a player to join...")
            }
        
        // hmmmm
        RealtimeDatabaseDelegate.shared.setObserver(key: game.id) { (dictionary) in
            print("callback")
            guard let board = self.board, let boardView = self.boardView else { return }
            guard let dict = dictionary else { return }
            do {
                try self.gameManager.decodeGame(from: dict)
                print("decoded game success")
                
                // game will start only if two players joined
                self.gameManager.startGame()
                
                // another guard let is needed here because game was updated after decoding and starting
                guard let currentGame = self.gameManager.current else { return }
                print("Current game started: \(currentGame.started), ended: \(currentGame.ended)")
                if currentGame.started {
                    
                    if !currentGame.ended {
                        self.showMessage(message: "")
                    }
                    
                    if currentGame.abandoned {
                        self.showMessage(message: "The other player abandoned the game")
                        return
                    }
                    
                    guard let lastMove = currentGame.getLastMove() else { return }
                    if currentGame.lastMoveIsWhite != self.playerIsWhite {
                            var move = Move(moveArray: lastMove)
                            move.isCastling = currentGame.lastMoveIsCastling
                            // Model: make move
                            board.makeMove(move)
                            // UI: update boardView
                            boardView.update(withMove: move)
                            // all the other stuff
                            self.whiteToMove = !self.whiteToMove
                            
                            if board.checkMate {
                                self.endGame(message: "Checkmate")
                                print("CHECKMATE ENDING GAME")
                            }
                            else if board.staleMate {
                                self.endGame(message: "Stalemate")
                            }
                            
                            let whiteKingUnderCheck = board.isKingUnderCheck(isWhite: true)
                            self.boardView.highlightCheck(kingCoordinates: board.whiteKing!.coordinates, turnOn: whiteKingUnderCheck, isWhite: true)
                            
                            let blackKingUnderCheck = board.isKingUnderCheck(isWhite: false)
                            self.boardView.highlightCheck(kingCoordinates: board.blackKing!.coordinates, turnOn: blackKingUnderCheck, isWhite: false)
                        }
                }
            } catch let err {
                print("Error in callback: ", err)
            }
        }
        print("You are playing \(self.playerIsWhite ? "white" : "black") pieces.")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard let game = self.gameManager.current else { return }
        self.gameManager.killGame(delete: !game.started || (game.abandoned))
    }
    
    func endGame(message: String) {
        self.gameManager.endGame()
        self.showMessage(message: message)
    }
    
    func showMessage(message: String) {
        self.messageLabel.text = message
        self.messageLabel.isHidden = false
    }
    

}

extension BoardViewController {
    
    private func getSquareCoordinates(fromTouch touch: UITouch) -> Coordinates {
        let touchPos = touch.location(in: self.boardView)
        let row = Int(floor(touchPos.y / self.boardView.squareSide))
        let col = Int(floor(touchPos.x / self.boardView.squareSide))
        
        return Coordinates(row: row, col: col)
    }
    
    private func handleTouch(_ touch: UITouch) {
        
        guard let game = self.gameManager.current else { return }
        
        if game.ended || !game.started || game.abandoned {
            return
        }
        
        guard let board = self.board, let boardView = self.boardView else { return }
        
        let touchedSquareCoordinates = self.getSquareCoordinates(fromTouch: touch)
                
        // if a piece was selected on a previous touch
        if let coordinates = self.selectedSquareCoordinates {
            
            // if a piece was selected twice in a row
            if coordinates == touchedSquareCoordinates {
                self.boardView.manageHighlighting(forCoordinates: coordinates)
                self.selectedSquareCoordinates = nil
                return
            }
            
            // create move instance
            var move = Move(from: coordinates, to: touchedSquareCoordinates)
            // validate move
            board.validateMove(&move)
            
            // if move is valid
            if move.valid {
                // Model: make move
                board.makeMove(move)
                // UI: update boardView
                boardView.update(withMove: move)

                // after a move was made there is no selected square
                self.selectedSquareCoordinates = nil
                self.whiteToMove = !self.whiteToMove
                
                if board.checkMate {
                    self.endGame(message: "Checkmate")
                }
                else if board.staleMate {
                    self.endGame(message: "Stalemate")
                }
                
                // Database: send move
                self.gameManager.writeMove(move, isWhite: self.playerIsWhite)
                
                let whiteKingUnderCheck = board.isKingUnderCheck(isWhite: true)
                self.boardView.highlightCheck(kingCoordinates: board.whiteKing!.coordinates, turnOn: whiteKingUnderCheck, isWhite: true)
                
                let blackKingUnderCheck = board.isKingUnderCheck(isWhite: false)
                self.boardView.highlightCheck(kingCoordinates: board.blackKing!.coordinates, turnOn: blackKingUnderCheck, isWhite: false)
            }
            
            // if move is not valid
            else {
                print("move is not valid: \(move)")
                // 1) touched square is empty or contains a piece of different color from the selected one
                if move.moveInvalidation! == .impossibleMove || move.moveInvalidation! == .ownKingUnderCheck {
                    // UI: turn off highlighting
                    boardView.turnOffLastHighlighted()
                    self.selectedSquareCoordinates = nil
                }
                // 2) touched square contains own piece
                else if move.moveInvalidation! == .toOwnPiece {
                    // UI: manage highlighting
                    boardView.manageHighlighting(forCoordinates: move.to)
                    self.selectedSquareCoordinates = touchedSquareCoordinates
                }
            }
            
        }
            
        // if a piece was not selected on a previous touch
        else {
            let touchedSquare = board.getSquare(fromCoordinates: touchedSquareCoordinates)
            
            // 1) touched square is empty - do nothing
            if touchedSquare.isEmpty {
                return
            }
            // 2) touched square contains a piece
            else {
                // manage moving in turns
                if board.getSquare(fromCoordinates: touchedSquareCoordinates).piece!.isWhite == self.playerIsWhite &&
                    self.whiteToMove == self.playerIsWhite {
                    
                    self.selectedSquareCoordinates = touchedSquareCoordinates
                    boardView.manageHighlighting(forCoordinates: touchedSquareCoordinates)
                    
                }
                else {
                    return
                }
                
                
            }
        }
        
    }
    
}



extension BoardViewController {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        // if the board was touched
        if boardView.subviews.contains(touch.view!) {
            self.handleTouch(touch)
        }
    }
    
}

