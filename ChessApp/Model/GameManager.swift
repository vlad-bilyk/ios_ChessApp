//
//  Game.swift
//  ChessApp
//
//  Created by Vlad Bilyk on 03.12.2020.
//  Copyright © 2020 Vlad Bilyk. All rights reserved.
//

import Foundation


public class GameManager {
    
    static let shared = GameManager()
    
    var databaseDelegate = RealtimeDatabaseDelegate.shared
    
    var current: Game?
        
    private init() { }
    
    func createGame(completion: (() -> ())? = nil) {
        let game = Game(player1: true, player2: false)
        
        self.encodeAndWrite(game, completion: completion)
        
        self.current = game
        
    }
    
    func joinGame(completion: (() -> ())?) {
        self.databaseDelegate.getAll { (dictionary) in
            guard let dict = dictionary else { return }
            print(dict)
            if dict.count == 0 {
                print("No games were found")
                return
            }
            
            do {
                let games = try self.decodedGamesDictionary(from: dict)
                
                for game in games.values {
                    if !game.player2 && !game.abandoned {
                        game.player2 = true
                        game.started = true
                        self.current = game
                        self.encodeAndWrite(game, completion: completion)
                        print("game [\(game.id)] was joined")
                        return
                    }
                }
                print("No games were found")
                
            } catch let err {
                print("Error joining game: ", err)
            }
        }
    }
    
    func updateGame(_ game: Game) {
        self.current = game
    }
    
    func startGame() {
        guard let game = self.current else { return }
        if game.player1 && game.player2 {
            game.started = true
        }
    }

    func endGame() {
        guard let game = self.current else { return }
        game.ended = true
    }
    
    // basically - leave game
    func killGame(delete: Bool) {
        guard let game = self.current else { return }
        print("killing game")
        self.endGame()
        game.abandoned = true
        self.databaseDelegate.removeAllObservers(forChild: game.id)
        
        if delete {
            self.databaseDelegate.delete(key: game.id)
            return
        }
        
        self.encodeAndWrite(game, completion: {
            self.current = nil
        })
    }
    
    func writeMove(_ move: Move, isWhite: Bool) {
        guard let game = self.current else { return }
        let moveArr = [move.from.toArray(), move.to.toArray()]
        game.lastMove = moveArr
        game.lastMoveIsWhite = isWhite
        game.lastMoveIsCastling = move.isCastling
        print("writing move, game ended: \(game.ended)")
        
        self.encodeAndWrite(game)
    }
    
    func encodeAndWrite(_ game: Game, completion: (() -> ())? = nil) {
        let dictionary = game.encoded()
        self.databaseDelegate.write(key: game.id, value: dictionary, completion: completion)
    }
    
    func decodedGamesDictionary(from dictionary: NSDictionary) throws -> [String : Game] {
        print("DECODED GAMES DICTIONARY")
        print(dictionary)
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        let games: [String : Game] = try JSONDecoder().decode([String : Game].self, from: jsonData)
        
        return games
    }
    
    func decodeGame(from dictionary: NSDictionary) throws {
        print("DECODING A SINGLE GAME")
        print(dictionary)
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        let game = try JSONDecoder().decode(Game.self, from: jsonData)
        
        self.current = game
    }
    
}
