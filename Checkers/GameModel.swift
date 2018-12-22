//
//  GameModel.swift
//  Checkers
//
//  Created by Ahmed  Daboor on 12/13/18.
//  Copyright © 2018 Ahmed  Daboor. All rights reserved.
//

import Foundation
import GameplayKit

class Player: NSObject, GKGameModelPlayer {     // Player class
    var playerId: Int = 0                       // Id for player
    var isComputer: Bool = false
    var opposite: Player { return self == .White ? .Black : .White }   // The opposite player
    
    static let White = Player(0, false)              // By default white is a player with id 0 and a human
    static let Black = Player(1, true)               // By default black is a player with id 1 and computer
    
    init(_ playerId: Int, _ isComputer: Bool) {      // Intializer for the player class
        self.playerId = playerId
        self.isComputer = isComputer
    }
    
    override var description: String {     //Define player description
        return (self == .White ? "White" : "Black") + (self.isComputer ? " (Computer)" : " (Human)")  // if not white must be black , if not computer must be human
    }
}

class Board: NSObject {         // Board Class
    var moves: [BitBoard] // cache for potential movements
    var board: BitBoard
    var move: Int // > 50 it's a draw
    
    convenience override init() {         // Convenience initilazier for the board class
        self.init(BitBoard())             //
    }
    
    init(_ board: BitBoard) {             // Intialize with selected bitboard
        self.board = board
        self.moves = board.makeIteratorCont().map { $0 }
        self.move = 0
    }
}

class Update: NSObject, GKGameModelUpdate {     // Class to update the game using GameModel protocol
    var board: BitBoard                         // The selected board
    var previous: BitBoard                      // The previous one
    var value: Int = 0                          // Value to count updates
    
    init(_ board: BitBoard, _ previous: BitBoard) {         // Intialize with the selected board with the previous one
        self.board = board                                  // Assign the pramaters to members of the class
        self.previous = previous
    }
    
    var move: (Int, Int)? {                      // Move function
        let (prev, next) = previous.player ? (previous.black, board.black) : (previous.white, board.white)
        let mask = prev ^ next
        guard let from = BitBoard.Mask(mask & prev).checkSet().first else { return nil }      // The previous mask
        guard let to = BitBoard.Mask(mask & next).checkSet().first else { return nil }        // The next mask
        return (from, to)
    }
    
    var capture: Int? {                       // Capture function
        let (prev, next) = previous.player ? (previous.white, board.white) : (previous.black, board.black)
        let mask = prev ^ next
        guard let from = BitBoard.Mask(mask & prev).checkSet().first else { return nil }
        return from
    }
    
    var promotion: Int? {                   // promotion function
        let (prev, next) = previous.player ? (previous.black, board.black) : (previous.white, board.white)
        let (prevQueen, nextQueen) = (prev & previous.queen, next & board.queen)
        if prevQueen == 0 && nextQueen != 0 {
            guard let promo = BitBoard.Mask(nextQueen).checkSet().first else { return nil }
            return promo
        }
        
        return nil
    }
}

extension Board: GKGameModel {              //
    var players: [GKGameModelPlayer]? {
        return [Player.White, Player.Black]
    }
    
    var activePlayer: GKGameModelPlayer? {
        guard !isDraw() else { return nil }
        guard !isWin(for: Player.Black) && !isWin(for: Player.White) else { return nil }
        //        guard !isLoss(for: Player.Black) && !isLoss(for: Player.White) else { return nil }
        
        return board.player ? Player.Black : Player.White
    }
    
    func setGameModel(_ gameModel: GKGameModel) {
        if let model = gameModel as? Board {
            self.board = model.board
            self.moves = model.moves
            self.move = model.move
        }
    }
    
    func gameModelUpdates(for player: GKGameModelPlayer) -> [GKGameModelUpdate]? {
        return moves.map { Update($0, self.board) }
    }
    
    func apply(_ gameModelUpdate: GKGameModelUpdate) {         //
        if let update = gameModelUpdate as? Update {
            self.board = update.board
            self.moves = board.makeIteratorCont().map { $0 }
            self.move += update.board.player != update.previous.player ? 1 : 0
        }
    }
    
    func unapplyGameModelUpdate(_ gameModelUpdate: GKGameModelUpdate) {
        if let update = gameModelUpdate as? Update {
            self.board = update.previous
            self.moves = board.makeIteratorCont().map { $0 }
            self.move -= update.board.player != update.previous.player ? 1 : 0
        }
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return Board(board)
    }
}

extension Board {
    func isDraw() -> Bool {                   // 50 turn for each player befor declared the game id Draw
        return move > 100
    }
    
    func isWin(for player: GKGameModelPlayer) -> Bool {
        guard let player = player as? Player else { return false }  // Player win if he is the last one stand
        
        return isLoss(for: player.opposite)           // Player loss if the other player is the last ine stand
    }
    
    func isLoss(for player: GKGameModelPlayer) -> Bool {
        // check we can move if active player
        if (player.playerId == 1) == board.player {
            guard moves.count > 0 else { return true }
        }
        
        // check if we have any pieces left
        return (player.playerId == 1 ? board.black : board.white) == 0
    }
    
    func score(for player: GKGameModelPlayer) -> Int {
        let position =                // Score for the startgey model intialized with array of numerical
            [8, 8, 8, 8,              // values for player 1
             6, 6, 6, 7,
             6, 4, 4, 5,
             4, 2, 3, 5,
             4, 2, 1, 3,
             3, 2, 2, 4,
             4, 3, 3, 3,
             4, 4, 4, 4]
        
        let pos2 =                   // Score for stratgey model intialized with array of numerical values for player 2
            [ 3, 3, 2, 1,
              4, 3, 2, 1,
              3, 4, 3, 2,
              3, 4, 3, 2,
              2, 3, 4, 3,
              2, 3, 4, 3,
              1, 2, 3, 4,
              1, 2, 3, 3]
        
        let (me, you) = player.playerId == 1 ? (board.black, board.white) : (board.white, board.black)
        let empty = ~(me | you)
        
        let val = (0..<32).reduce(0) {
            let mask = BitBoard.Mask(maskIndex: $1)
            guard empty & mask == 0 else { return $0 }
            let score: Int
            if board.queen & mask != 0 {
                score = 15 + pos2[$1]
            } else {
                score = 5 + position[player.playerId != 0 ? 31 - $1 : $1]
            }
            return me & mask != 0 ? $0 + score : $0 - score
        }
        
        return val
    }
}

extension Board {
    func checkSet() -> [Int] {
        return (board.white | board.black).checkSet()           
    }
    
    func isQueen(_ index: Int) -> Bool {            // Check if the mask is for queen
        return board.queen.hasIndex(maskIndex: BitBoard.MaskIndex(checkIndex: index))
    }
    
    func isWhite(_ index: Int) -> Bool {           // Check if the mask for Player 1
        return board.white.hasIndex(maskIndex: BitBoard.MaskIndex(checkIndex: index))
    }
    
    func update(_ from: Int, _ to: Int) -> Update? {        // update function to apply movement
        let from = BitBoard.MaskIndex(checkIndex: from)     // start
        let to = BitBoard.MaskIndex(checkIndex: to)         // end
        guard let update = board.applyMove(from: from, to: to) else { return nil } // Apply move
        return Update(update, self.board)
    }
}
