//
//  GameScene.swift
//  Checkers
//
//  Created by Ahmed  Daboor on 12/13/18.
//  Copyright © 2018 Ahmed  Daboor. All rights reserved.
//

import SpriteKit
import GameplayKit


class GameScene: SKScene {
    
    var strategist: GKStrategist!    // The starategy to choose
    var gameModel: Board { return strategist.gameModel as! Board }  // Model to play with for AI
    
    var board: SKNode!               // The board
    var label: SKLabelNode!
    var newLabel: SKLabelNode!
    var whiteLabel: SKLabelNode!     // Lable for player 1
    var blackLabel: SKLabelNode!     // Lable for player 2
    var pieces: [SKNode?] = Array(repeating: nil, count: 64)  // Add 64 pieces for all possible locations intialized with null to avoid implicit call
    
    func isValidIndex(index i: Int) -> Bool {                 // Function to check the index
        return (i >> 3) & 1 == i & 1
    }
    
    func locationForIndex(index i: Int) -> CGPoint {          // Get the location of desierd index to detect touches
        let x = check * CGFloat((i % 8) - 4) + check / 2
        let y = check * CGFloat((i / 8) - 4) + check / 2
        return CGPoint(x: x, y: y)
    }
    
    func indexForLocation(location l: CGPoint) -> Int? {    // Get the location of desierd index to detect touches
        guard abs(l.x) < (side / 2) && abs(l.y) < (side / 2) else { return nil }
        
        let i = l.x / check + 4
        let j = l.y / check + 4
        
        let pos = Int(floor(i) + floor(j) * 8)
        print(pos)
        
        return pos
    }
    
    var side: CGFloat { return min(size.width, size.height) * 0.9 }       // side of square
    var check: CGFloat { return side / 8}                                 // checkers pices
    var radius: CGFloat { return check * 0.4 }                            //raduis
    
    override func didChangeSize(_ oldSize: CGSize) {                     //
        board?.position = CGPoint(x: frame.midX, y: frame.midY)          // the new size assigned to board position
    }
    
    override func didMove(to view: SKView) {
        strategist = GKMonteCarloStrategist()                          // Chose Monte carlo stratgey
       
        strategist.randomSource = GKLinearCongruentialRandomSource()  //  value To generate basic random values with this random source,
        strategist.gameModel = Board(BitBoard())                 
        
        board = SKShapeNode(rectOf: CGSize(width: side, height: side))  //Creates a shape node with a rectangular path centered on the node’s origin.
        board.name = "board"                                           // Assign a name
        board.position = CGPoint(x: frame.midX, y: frame.midY)         //The position of the node in its parent's coordinate system.
        addChild(board)                                                // Add child
        
        let fontSize = side / 32                                       // font size
        let offset = CGPoint(x: side / 2, y: side / 2 + fontSize * 1.5)
        
        label = SKLabelNode(text: "Checkers!")                         // Checkers lable
        label.verticalAlignmentMode = .baseline
        label.horizontalAlignmentMode = .right
        label.fontSize = fontSize
        label.fontColor = SKColor.yellow
        label.fontName = "Avenir"
        label.position = CGPoint(x: offset.x, y: -offset.y)
        board.addChild(label)
        
        newLabel = SKLabelNode(text: "New Game")      // New game lable
        newLabel.verticalAlignmentMode = .baseline
        newLabel.horizontalAlignmentMode = .left
        newLabel.fontSize = fontSize
        newLabel.fontColor = SKColor.yellow
        newLabel.fontName = "Avenir"
        newLabel.position = CGPoint(x: -offset.x, y: offset.y - fontSize)
        board.addChild(newLabel)
        
        whiteLabel = SKLabelNode(text: "\(Player.White)")    // Player 1 lable properties
        whiteLabel.verticalAlignmentMode = .baseline
        whiteLabel.horizontalAlignmentMode = .left
        whiteLabel.fontSize = fontSize
        whiteLabel.fontColor = .white
        whiteLabel.fontName = "Avenir"
        whiteLabel.position = CGPoint(x: -offset.x, y: -offset.y)
        board.addChild(whiteLabel)
        
        blackLabel = SKLabelNode(text: "\(Player.Black)")  // Player 2 lable properties
        blackLabel.verticalAlignmentMode = .baseline
        blackLabel.horizontalAlignmentMode = .right
        blackLabel.fontSize = fontSize
        blackLabel.fontColor = .white
        blackLabel.fontName = "Avenir"
        blackLabel.position = CGPoint(x: offset.x, y: offset.y - fontSize)
        board.addChild(blackLabel)
        
        for i in 0..<64 {
            let position = locationForIndex(index: i)
            
            let square = SKShapeNode(rectOf: CGSize(width: check, height: check))   // Square shape of cell intializer
            let gray = isValidIndex(index: i)   //assign gray var for not vaild celles
            square.fillColor = gray ? .clear : .gray   // if not true assign the gray colure
            square.position = position                 // The position of the node in its parent's coordinate system.
            square.name = "square"                     // Assign a name
            board.addChild(square)
            
            if isValidIndex(index: i) {              // Add a lable with number for each movment cell
                let label = SKLabelNode(text: "\(i >> 1)")
                label.fontSize = radius * 0.8
                label.fontColor = .yellow
                label.verticalAlignmentMode = .center
                label.horizontalAlignmentMode = .center
                label.position = position
                label.name = "label"
                label.zPosition = 9
                board.addChild(label)
            }
        }
        
        resetBoard()             // Reset the board after movment
    }
    
    func resetBoard() {          // Function to reset board
        board.enumerateChildNodes(withName: "piece", using: { (node, nil) in          //This method enumerates the child array in order, searching
            node.removeFromParent()                                                   //for nodes whose names match the search parameter.
        })
        
        pieces = Array(repeating: nil, count: 64)                                     // Re-intialize the array of pieces
        
        for index in gameModel.checkSet() {                                           // Return all the previous pieces
            let color: SKColor = gameModel.isWhite(index) ? .red : .blue              // Assign there colures to the inner circles
            let piece = SKShapeNode(circleOfRadius: radius)                           // Piece creation
            let inner = SKShapeNode(circleOfRadius: radius * 0.8)                     // Inner circle creation
            inner.fillColor = color
            piece.addChild(inner)                                                     // Add a child to the parent node
            piece.position = self.locationForIndex(index: index)
            piece.name = "piece"
            piece.fillColor = gameModel.isQueen(index) ? .yellow : color // If the piece turned to be a queen add yellow tag
            piece.zPosition = 2
            
            pieces[index] = piece                                        // Add the piece to the array
            
            board.addChild(piece)                                        // Add piece as a child to the board
        }
        
        nextTurn()                                                       // Call next turn
    }
    
    var moving: SKNode?                              // Variable to detect moving
    var fromPosition: CGPoint?                       // The index  of touch
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)     // Function to call when the board is touched
    {
        for touch in touches {             
            if whiteLabel.contains(touch.location(in: board)) {                   // If the white lable is touched
                Player.White.isComputer = !Player.White.isComputer                // Change the player1 mode
                whiteLabel.text = "\(Player.White)"
                if let activePlayer = gameModel.activePlayer as? Player, activePlayer == Player.White {
                    nextTurn()
                }
                return
            }
            
            if blackLabel.contains(touch.location(in: board)) {                  //if the black lable is touhed
                Player.Black.isComputer = !Player.Black.isComputer               //change the player2 mode
                blackLabel.text = "\(Player.Black)"
                if let activePlayer = gameModel.activePlayer as? Player, activePlayer == Player.Black {
                    nextTurn()
                }
                return
            }
        }
        
        if let activePlayer = gameModel.activePlayer as? Player {
            guard !activePlayer.isComputer else { return }
        }
        
        for touch in touches {
            if newLabel.contains(touch.location(in: board)) {
                strategist.gameModel = Board(BitBoard())
                resetBoard()
                return
            }
            
            let location = touch.location(in: board)
            
            for node in board.nodes(at: location) {
                guard node.name == "piece", node.contains(location) else { continue }
                
                moving = node
                node.zPosition = 3
                fromPosition = node.position
                return
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = moving, let touch = touches.first else { return }
        node.position = touch.location(in: board)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = moving, let touch = touches.first else { return }
        
        defer {
            node.position = fromPosition!
            node.zPosition = 1
            moving = nil
            fromPosition = nil
        }
        
        let newLocation = touch.location(in: board)
        guard let to = indexForLocation(location: newLocation) else { return }
        guard let from = indexForLocation(location: fromPosition!) else { return }
        guard let update = gameModel.update(from, to) else { return }
        
        let action = SKAction.move(to: locationForIndex(index: to), duration: 0.0)
        runAction(action, node)
        
        updateBoard(update)
        nextTurn()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = moving else { return }
        
        node.position = fromPosition!
        node.zPosition = 1
        moving = nil
        fromPosition = nil
    }
    
    func runAction(_ action:SKAction, _ piece: SKNode) {
        if piece.hasActions() {
            DispatchQueue.main.async {
                action.timingMode = SKActionTimingMode.easeIn
                self.runAction(action, piece)
            }
        } else {
            piece.run(action)
        }
    }
    
    func updateBoard(_ update: Update) {
        gameModel.apply(update)
        print("move: \(String(describing: update.move))")
        print("capture: \(String(describing: update.capture))")
        print("promotion: \(String(describing: update.promotion))")
        
        let duration = Player.White.isComputer && Player.Black.isComputer ? 0.01 : 0.25
        
        if let (from, to) = update.move, let piece = pieces[from] as? SKShapeNode {
            pieces[to] = pieces[from]
            pieces[from] = nil
            
            let action = SKAction.move(to: locationForIndex(index: to), duration: duration)
            if gameModel.isQueen(from) == gameModel.isQueen(to) {
                runAction(action, piece)
            } else {
                let color = piece.fillColor
                let glow = SKAction.customAction(withDuration: duration) { (node, elapsedTime) in
                    piece.fillColor = UIColor.interpolate(from: color, to: .white, with: elapsedTime / CGFloat(duration))
                }
                let group = SKAction.group([action, glow])
                runAction(group, piece)
            }
        }
        
        if let pos = update.capture, let piece = pieces[pos] {
            pieces[pos] = nil
            piece.zPosition = 1
            
            let action = SKAction.sequence([SKAction.fadeOut(withDuration: duration), SKAction.removeFromParent()])
            runAction(action, piece)
        }
    }
    
    func nextTurn() {
        
        if let player = gameModel.activePlayer as? Player {
            if player.isComputer {
                label.text = "Thinking ..."
                DispatchQueue.global(qos: .background).async {
                    DispatchQueue.main.async {
                        if let update = self.strategist.bestMoveForActivePlayer() as? Update {
                            self.updateBoard(update)
                        } else {
                            print("wat")
                        }
                        self.nextTurn()
                    }
                }
            } else {
                label.text =  "Move!" + " (\(gameModel.move))"
            }
        } else {
            if gameModel.isWin(for: Player.White) {
                label.text = "\(Player.White) wins!"
            } else if gameModel.isWin(for: Player.Black) {
                label.text = "\(Player.Black) wins!"
            } else {
                label.text = "Draw at move \(gameModel.move)"
            }
        }
    }
}

public extension UIColor {
    var components: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let components = self.cgColor.components!
        
        switch components.count == 2 {
        case true : return (r: components[0], g: components[0], b: components[0], a: components[1])
        case false: return (r: components[0], g: components[1], b: components[2], a: components[3])
        }
    }
    
    static func interpolate(from fromColor: UIColor, to toColor: UIColor, with progress: CGFloat) -> UIColor {
        let fromComponents = fromColor.components
        let toComponents = toColor.components
        
        let r = (1 - progress) * fromComponents.r + progress * toComponents.r
        let g = (1 - progress) * fromComponents.g + progress * toComponents.g
        let b = (1 - progress) * fromComponents.b + progress * toComponents.b
        let a = (1 - progress) * fromComponents.a + progress * toComponents.a
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
