//
//  GameScene.swift
//  BookCore
//
//  Created by Maria Fernanda Azolin on 12/05/20.
//

import PlaygroundSupport
import SpriteKit
import UIKit


public class GameScene: SKScene, UIPickerViewDelegate, UIPickerViewDataSource {
        
    
    //map and general app variables
    var tileArray: [[Tile]] = [[Tile]]()
    let startButton = SKSpriteNode(imageNamed: "start")
    let clearButton = SKSpriteNode(imageNamed: "clear")
    var posX = 0
    var posY = 0
    var marginX = 42
    var marginY = 100
    let rows = 20
    let columns = 15
    let nodeSize = 30
    let algorithmsPickerOptions = ["A*", "Dijkstra", "Breadth-first"]
    
    //all searches variables
    var playerPos = CGPoint(x: 5, y: 10)
    var targetPos = CGPoint(x: 12, y: 12)
    var alreadyFoundTarget = false
    var targetId = 0
    var playerId = 0
    var movingPlayer = false
    var movingTarget = false
    
    //A* variables
    var lowestCostId = 0
    var lowestCostIndex = 0
    var openList : [Tile] = [Tile]()
    var closedList : [Tile] = [Tile]()
    typealias Pos = (x: Int, y: Int)
    
    //Dijkstra and Breadth-first variables
    var unexploredList : [Tile] = [Tile]()
    
    //playground pages variables
    public var algorithm : String = "A*"
    
    //drawing variables
    var paintIdList : [Int] = [Int]()
    var pathIdList : [Int] = [Int]()
    var shouldDraw = false
    var shouldPaint = false
    var drawingSpeed = 0.2
    var timer : Timer? = Timer()
    
    
    override public func didMove(to view: SKView) {
        
        self.anchorPoint = CGPoint(x: 0, y: 0)
        
        var id = 0
        for column in 0...columns-1 {
            
            tileArray.append([Tile]())
            
            for row in 0...rows-1 {
                
                let square = Tile()
                
                posX = marginX + column * nodeSize
                posY = marginY + row * nodeSize
                
                square.tile.alpha = 0.2
                square.tile.position = CGPoint(x: posX, y: posY)
                square.tile.size = CGSize(width: nodeSize, height: nodeSize)
                
                square.id = id
                square.x = column
                square.y = row
                id += 1
                
                self.tileArray[column].append(square)
                self.addChild(square.tile)
                
            }
        }
        
        setPlayerAndTarget()
        
        createButtons()
        
        createPickerView()
    }
    
    func createButtons() {
        
        startButton.position = CGPoint(x: 425, y: 720)
        startButton.zPosition = 1
        startButton.size = CGSize(width: 112.0, height: 36.0)
        startButton.name = "startButton"
        startButton.isUserInteractionEnabled = false
        self.addChild(startButton)
        
        clearButton.position = CGPoint(x: 280, y: 720)
        clearButton.zPosition = 1
        clearButton.size = CGSize(width: 82.0, height: 34.0)
        clearButton.name = "clearButton"
        clearButton.isUserInteractionEnabled = false
        self.addChild(clearButton)
        
    }
    
    func resetSearchVariables() {
        
        for column in 0...tileArray.count-1 {
            for row in 0...tileArray[0].count-1 {
                tileArray[column][row].alreadyVisitedNode = false
                tileArray[column][row].fCost = 999.0
                tileArray[column][row].gCost = 0.0
                tileArray[column][row].hCost = 0.0
                tileArray[column][row].currentTile = false
                tileArray[column][row].isOnOpenList = false
                tileArray[column][row].tile.texture = SKTexture(imageNamed: "visitedNode")
                tileArray[column][row].tile.alpha = 0.2
                tileArray[column][row].isObstacle = false
                tileArray[column][row].parentId = 0
            }
        }
        
        unexploredList.removeAll()
        closedList.removeAll()
        openList.removeAll()
        
        setPlayerAndTarget()
        
        alreadyFoundTarget = false
        
        pathIdList.removeAll()
        paintIdList.removeAll()
    }
    
    func animateObstacleAtPos(column: Int, row: Int) {
        let rotate = SKAction.rotate(byAngle: (2 * .pi) , duration: 0.5)
        let growUp = SKAction.scale(to: 1.5, duration: 0.25)
        let growDown = SKAction.scale(to: 1, duration: 0.25)
        let group = SKAction.group([growUp, rotate])
        let sequence = SKAction.sequence([group, growDown])
        
        tileArray[column][row].tile.run(sequence)
    }
    
    func animateTarget(column: Int, row: Int) {
        let fadeIn = SKAction.fadeIn(withDuration: 1.8)
        let fadeOut = SKAction.fadeOut(withDuration: 1.8)
        let sequence = SKAction.sequence([fadeIn, fadeOut])
        let repeatSequence = SKAction.repeatForever(sequence)
        
        tileArray[column][row].tile.run(repeatSequence)
    }
    
    func setPlayerAndTarget() {
        tileArray[Int(playerPos.x)][Int(playerPos.y)].isPlayer = true
        tileArray[Int(playerPos.x)][Int(playerPos.y)].tile.texture = SKTexture(imageNamed: "planet")
        tileArray[Int(playerPos.x)][Int(playerPos.y)].tile.size = CGSize(width: 45, height: 36.8)
        tileArray[Int(playerPos.x)][Int(playerPos.y)].tile.alpha = 1.0
        
        tileArray[Int(targetPos.x)][Int(targetPos.y)].isTarget = true
        tileArray[Int(targetPos.x)][Int(targetPos.y)].tile.texture = SKTexture(imageNamed: "star")
        tileArray[Int(targetPos.x)][Int(targetPos.y)].tile.size = CGSize(width: 60, height: 42.4)
        animateTarget(column: Int(targetPos.x), row: Int(targetPos.y))
        
        playerId = tileArray[Int(playerPos.x)][Int(playerPos.y)].id
        targetId = tileArray[Int(targetPos.x)][Int(targetPos.y)].id
    }
    
    func euclideanDistance(x1 : Double, y1 : Double, x2 : Double, y2 : Double) -> Double {
        return sqrt(pow((x1-x2), 2) + pow((y1-y2), 2))
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
        if clearButton.contains(pos){
            resetSearchVariables()
        }
        else if startButton.contains(pos) {
            resetSearchVariables()
            if !alreadyFoundTarget {
                
                switch algorithm {
                case "A*" :
                    _ = self.aStar()
                case "Dijkstra" :
                    _ = self.dijkstra()
                case "Breadth-first" :
                    _ = self.dijkstra()
                default:
                    _ = aStar()
                }
                createDrawPathList()
                
                timer = Timer.scheduledTimer(timeInterval: drawingSpeed, target: self, selector: #selector(GameScene.paintVisitedTile), userInfo: nil, repeats: true)
            }
            
        }
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
        for column in 0...tileArray.count-1 {
            for row in 0...tileArray[0].count-1 {
                
                if !((row == Int(playerPos.y) && column == Int(playerPos.x)) || (row == Int(targetPos.y) && column == Int(targetPos.x))) {
                    //if it's not the player neither the target
                    if tileArray[column][row].tile.contains(pos) && !movingPlayer && !movingTarget {
                        if !tileArray[column][row].isObstacle {
                            
                            tileArray[column][row].tile.texture = SKTexture(imageNamed: "void")
                            tileArray[column][row].tile.size = CGSize(width: 30, height: 34.5)
                            tileArray[column][row].tile.alpha = 1.0
                            tileArray[column][row].tile.zPosition = 2
                            tileArray[column][row].isObstacle = true
                            
                            animateObstacleAtPos(column: column, row: row)
                        }
                    }
                }
                else {
                    if tileArray[column][row].tile.contains(pos) {
                        if (row == Int(playerPos.y) && column == Int(playerPos.x)) {
                            //if it's moving the player
                            movingPlayer = true
                            tileArray[column][row].isPlayer = false
                            tileArray[column][row].tile.texture = SKTexture(imageNamed: "visitedNode")
                            tileArray[column][row].tile.size = CGSize(width: nodeSize, height: nodeSize)
                            tileArray[column][row].tile.alpha = 0.2
                        }
                        if (row == Int(targetPos.y) && column == Int(targetPos.x)) {
                            //if it's moving the target
                            movingTarget = true
                            tileArray[column][row].isTarget = false
                            tileArray[column][row].tile.removeAllActions()
                            tileArray[column][row].tile.texture = SKTexture(imageNamed: "visitedNode")
                            tileArray[column][row].tile.size = CGSize(width: nodeSize, height: nodeSize)
                            tileArray[column][row].tile.alpha = 0.2
                        }
                    }
                }
                
            }
        }
    }
    
    func breadthFirst() -> Bool {
        
        //set all the node’s distances to infinity and add them to an unexplored set
        //in this case we use fCost as the distance
        copyTileArrayToUnexploredList()
        
        //Set the starting node’s distance to 0
        let startingNodePos = tileArray[Int(playerPos.x)][Int(playerPos.y)].id
        unexploredList[startingNodePos].fCost = 0
        
        while !alreadyFoundTarget {
            
            //look for the node with the lowest distance, let this be the current node
            unexploredList.sort(by: { $0.fCost > $1.fCost }) //sorts in descendent order
            let currSquare = unexploredList.last!
            let currentSquarePos = CGPoint(x: currSquare.x, y: currSquare.y)
            
            if currSquare.isTarget {
                //achou
                
                alreadyFoundTarget = true
                targetId = currSquare.id

                return true
            }
            
            //remove it from the unexplored set
            if unexploredList.count > 0 {
                unexploredList.removeLast()
            } else {
                return false
            }
            
            
            //for each of the nodes adjacent to this node…
            for offsetY in -1...1 {
                for offsetX in -1...1 {
                    let row = Int(currentSquarePos.y) + offsetY
                    let column = Int(currentSquarePos.x) + offsetX
                    
                    if (column < columns && column >= 0) && (row >= 0 && row < rows) {
                        //if it's not out of the screen
                        let nextCandidate = tileArray[column][row]
                        
                        if !(nextCandidate.isPlayer) {
                            //if it isn't itself
                            
                            if !(nextCandidate.isObstacle) {
                                
                                //stores the tile's id to be painted
                                if !paintIdList.contains(nextCandidate.id){
                                    paintIdList.append(nextCandidate.id)
                                }
                                
                                //calculate a potential new distance
                                //current node’s distance plus the distance to the adjacent node you are at
                                let potentialNewDistance = currSquare.fCost + 1
                                
                                
                                //If the potential distance is less than the adjacent node’s current distance,
                                //then set the adjacent node’s distance to the potential new distance
                                //and set the adjacent node’s parent to the current node
                                if potentialNewDistance < nextCandidate.fCost {
                                    nextCandidate.fCost = potentialNewDistance
                                    nextCandidate.parentId = currSquare.id
                                }
                            }
                        }
                    }
                }
            }
            
        }
        
        return true
    }
    
    func dijkstra() -> Bool {
        
        //set all the node’s distances to infinity and add them to an unexplored set
        //in this case we use fCost as the distance
        copyTileArrayToUnexploredList()
        
        //Set the starting node’s distance to 0
        let startingNodePos = tileArray[Int(playerPos.x)][Int(playerPos.y)].id
        unexploredList[startingNodePos].fCost = 0
        
        while !alreadyFoundTarget {
            
            //look for the node with the lowest distance, let this be the current node
            unexploredList.sort(by: { $0.fCost > $1.fCost }) //sorts in descendent order
            let currSquare = unexploredList.last!
            let currentSquarePos = CGPoint(x: currSquare.x, y: currSquare.y)
            
            if currSquare.isTarget {
                //achou
                
                alreadyFoundTarget = true
                targetId = currSquare.id
                
                return true
            }
            
            //remove it from the unexplored set
            if unexploredList.count > 0 {
                unexploredList.removeLast()
            } else {
                return false
            }
            
            
            //for each of the nodes adjacent to this node…
            for offsetY in -1...1 {
                for offsetX in -1...1 {
                    let row = Int(currentSquarePos.y) + offsetY
                    let column = Int(currentSquarePos.x) + offsetX
                    
                    if (column < columns && column >= 0) && (row >= 0 && row < rows) {
                        //if it's not out of the screen
                        let nextCandidate = tileArray[column][row]
                        
                        if !(nextCandidate.isPlayer) {
                            //if it isn't itself
                            
                            if !(nextCandidate.isObstacle) {
                                
                                //stores the tile's id to be painted
                                if !paintIdList.contains(nextCandidate.id){
                                    paintIdList.append(nextCandidate.id)
                                }
                                
                                
                                //calculate a potential new distance
                                //current node’s distance plus the distance to the adjacent node you are at
                                let potentialNewDistance = offsetX == 0 || offsetY == 0
                                    ? currSquare.fCost + 1
                                    : currSquare.fCost + 1.5
                                
                                //If the potential distance is less than the adjacent node’s current distance,
                                //then set the adjacent node’s distance to the potential new distance
                                //and set the adjacent node’s parent to the current node
                                
                                if potentialNewDistance < nextCandidate.fCost {
                                    nextCandidate.fCost = potentialNewDistance
                                    nextCandidate.parentId = currSquare.id
                                }
                            }
                        }
                    }
                }
            }
            
        }
        
        return true
        
    }
    
    func copyTileArrayToUnexploredList() {
        for column in 0...tileArray.count-1 {
            for row in 0...tileArray[0].count-1 {
                unexploredList.append(tileArray[column][row])
            }
        }
    }
    
    func aStar() -> Bool {
        
        openList.append(tileArray[Int(playerPos.x)][Int(playerPos.y)])
        tileArray[Int(playerPos.x)][Int(playerPos.y)].isOnOpenList = true
        
        while !alreadyFoundTarget {
            
            //Looks for the lowest F cost square on the open list
            var lowestCost = 9999.0
            
            for (index, candidate) in openList.enumerated() {
                if candidate.fCost < lowestCost && candidate.alreadyVisitedNode == false {
                    lowestCost = candidate.fCost
                    lowestCostId = candidate.id
                    lowestCostIndex = index
                }
            }
            
            //lowestCostIndex is the "current square"
            let currSquare = openList[lowestCostIndex]
            let currentSquarePos = CGPoint(x: currSquare.x, y: currSquare.y)
            
            //Switch it to the closed list
            tileArray[Int(currentSquarePos.x)][Int(currentSquarePos.y)].alreadyVisitedNode = true
            closedList.append(currSquare)
            
            openList.remove(at: lowestCostIndex)
            
            if currSquare.isTarget {
                //found target
                
                targetId = currSquare.id
                alreadyFoundTarget = true
                
                return true
            }
            
            //the current square on the tileArray is the tile with currentSquarePos
            //for each of the 8 squares adjacent to this current square...
            for offsetY in -1...1 {
                for offsetX in -1...1 {
                    let row = Int(currentSquarePos.y) + offsetY
                    let column = Int(currentSquarePos.x) + offsetX
                    
                    if (column < columns && column >= 0) && (row >= 0 && row < rows) {
                        let nextCandidate = tileArray[column][row]
                        //if it's not out of the screen
                        if !(nextCandidate.isPlayer) {
                            //if it isn't itself
                            if !(nextCandidate.isObstacle) && !(nextCandidate.alreadyVisitedNode) {
                                //if it's not an obstacle and has not been visited yet
                                //if it isn’t on the open list, add it to the open list
                                if !nextCandidate.isOnOpenList {
                                    openList.append(nextCandidate)
                                    nextCandidate.isOnOpenList = true
                                    
                                    //stores the tile's id to be painted
                                    if !paintIdList.contains(nextCandidate.id){
                                        paintIdList.append(nextCandidate.id)
                                    }
                                    
                                    //make the current square the parent of this square
                                    nextCandidate.parentId = currSquare.id
                                    
                                    //record the F, G, and H costs of the square
                                    nextCandidate.hCost = euclideanDistance(x1: Double(column), y1: Double(row), x2: Double(targetPos.x), y2: Double(targetPos.y))
                                    
                                    if offsetX == 0 || offsetY == 0 {
                                        //if the tile is horizontal or vertical
                                        nextCandidate.gCost = currSquare.gCost + 1
                                    } else {
                                        //if it is a diagonal
                                        nextCandidate.gCost = currSquare.gCost + 1.5
                                    }
                                    
                                    
                                    nextCandidate.fCost = nextCandidate.gCost + nextCandidate.hCost
                                    
                                } else {
                                    //check to see if this path to that square is better
                                    
                                    let potentialGCost = offsetX == 0 || offsetY == 0
                                        ? currSquare.gCost + 1
                                        : currSquare.gCost + 1.5
                                    
                                    if nextCandidate.gCost > potentialGCost {
                                        //change the parent of the square to the current square
                                        nextCandidate.parentId = currSquare.id
                                        //recalculate the G and F scores of the square
                                        nextCandidate.gCost = potentialGCost
                                        nextCandidate.fCost = nextCandidate.gCost + nextCandidate.hCost
                                    }
                                }
                                
                            }
                        }
                    }
                }
            }
        }
        return true
    }
    
    func createDrawPathList() {
        let targetPos = idToPos(id: targetId)
        var drawingTile = tileArray[targetPos.x][targetPos.y]
        
        while !drawingTile.isPlayer {
            if !drawingTile.isTarget {
                pathIdList.append(drawingTile.id)
            }
            
            let nextPos = idToPos(id: drawingTile.parentId)
            drawingTile = tileArray[nextPos.x][nextPos.y]
        }
    }
    
    
    func idToPos(id: Int) -> Pos {
        return Pos(y: id % rows, x: Int(id/rows))
    }
    
    func posToId(pos: Pos) -> Int {
        return (rows*pos.x + pos.y)
    }
    
    
    func touchUp(atPoint pos : CGPoint) {
        if movingPlayer {
            for column in 0...tileArray.count-1 {
                for row in 0...tileArray[0].count-1 {
                    if tileArray[column][row].tile.contains(pos) {
                        tileArray[column][row].tile.texture  = SKTexture(imageNamed: "planet")
                        tileArray[column][row].tile.size = CGSize(width: 45, height: 36.8)
                        tileArray[column][row].tile.alpha = 1.0
                        tileArray[column][row].isPlayer = true
                        playerPos.x = CGFloat(column)
                        playerPos.y = CGFloat(row)
                        playerId = posToId(pos: Pos(column, row))
                    }
                    
                }
            }
            movingPlayer.toggle()
        }
        
        if movingTarget {
            for column in 0...tileArray.count-1 {
                for row in 0...tileArray[0].count-1 {
                    if tileArray[column][row].tile.contains(pos) {
                        tileArray[column][row].tile.texture  = SKTexture(imageNamed: "star")
                        tileArray[column][row].tile.size = CGSize(width: 60, height: 42.4)
                        tileArray[column][row].tile.alpha = 1.0
                        tileArray[column][row].isTarget = true
                        animateTarget(column: column, row: row)
                        targetPos.x = CGFloat(column)
                        targetPos.y = CGFloat(row)
                        targetId = posToId(pos: Pos(column, row))
                    }
                    
                }
            }
            movingTarget.toggle()
        }
        
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchDown(atPoint: t.location(in: self)) }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchMoved(toPoint: t.location(in: self)) }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchUp(atPoint: t.location(in: self)) }
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchUp(atPoint: t.location(in: self)) }
    }
    
    override public func update(_ currentTime: TimeInterval) {

        
    }
    
    @objc func paintPath() {
        
        let id = pathIdList.first
        let pos = idToPos(id: id ?? 0)
        
        tileArray[pos.x][pos.y].tile.alpha = 1.0
        tileArray[pos.x][pos.y].tile.texture = SKTexture(imageNamed: "pathNode")

        if pathIdList.count > 1 {
            pathIdList.removeFirst()
        } else {
            tileArray[Int(playerPos.x)][Int(playerPos.y)].tile.texture = SKTexture(imageNamed: "planet")
            tileArray[Int(playerPos.x)][Int(playerPos.y)].tile.zPosition = 3
            if timer != nil {
                timer!.invalidate()
                timer = nil
            }
        }
    }
    
    @objc func paintVisitedTile() {
        
        let id = paintIdList.first
        let pos = idToPos(id: id ?? 0)
        
        if !(pos.x == Int(targetPos.x) && pos.y == Int(targetPos.y)) {
            tileArray[pos.x][pos.y].tile.alpha = 1.0
        }
        
        if paintIdList.count > 1 {
            paintIdList.removeFirst()
        } else {
            if timer != nil {
                timer!.invalidate()
                timer = nil
            }
            
            timer = Timer.scheduledTimer(timeInterval: drawingSpeed, target: self, selector: #selector(GameScene.paintPath), userInfo: nil, repeats: true)
        }
        
    }
    
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return algorithmsPickerOptions.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return algorithmsPickerOptions[row]
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        algorithm = algorithmsPickerOptions[row]
    }
    
    func createPickerView() {
        guard let view = view else { return }
        
        let myPickerView  : UIPickerView = UIPickerView()
        myPickerView.dataSource = self
        myPickerView.delegate = self
        
        view.addSubview(myPickerView)
        
        myPickerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            myPickerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            myPickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            myPickerView.widthAnchor.constraint(equalToConstant: 100)
        ])
        
        
    }
    
}

