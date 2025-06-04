import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var spinnyNode : SKShapeNode?
    
    var gridOrigin = CGPoint.zero
    
    let numRows = 12
    let numCols = 8
    let tileSize: CGFloat = 40
    
    var ballPosition = CGPoint(x: Int.random(in: 1...6), y: Int.random(in: 1...6))
    var holePosition = CGPoint(x: Int.random(in: 1...6), y: Int.random(in: 1...6))
    
    var ballNode: SKShapeNode!
    var holeNode: SKSpriteNode!
    var randomButtonNode: SKSpriteNode!
    var numberLabel: SKLabelNode!
    
    var tileMap: [[SKShapeNode]] = []
    
    let directionMap: [String: CGVector] = [
        "dir_0": CGVector(dx: 0, dy: 1),
        "dir_1": CGVector(dx: 0, dy: -1),
        "dir_2": CGVector(dx: -1, dy: 0),
        "dir_3": CGVector(dx: 1, dy: 0)
    ]

    override func didMove(to view: SKView) {
        backgroundColor = .brown // Set default background color

        // Set gridOrigin before placing anything
        gridOrigin = CGPoint(
            x: (size.width - CGFloat(numCols) * tileSize) / 2,
            y: (size.height - CGFloat(numRows) * tileSize) / 2
        )

        drawGrid()
        addHole()
        addBall()
        addDirectionButton()
        addNumberLabel()
    }

    func drawGrid() {
        tileMap = []
        for row in 0..<numRows {
            var rowArray: [SKShapeNode] = []
            for col in 0..<numCols {
                let tile = SKShapeNode(rectOf: CGSize(width: tileSize, height: tileSize))
                tile.strokeColor = .black
                tile.fillColor = .green // Grid tiles are green
                tile.name = "tile_\(col)_\(row)"
                tile.position = CGPoint(
                    x: CGFloat(col) * tileSize + tileSize / 2 + gridOrigin.x,
                    y: CGFloat(row) * tileSize + tileSize / 2 + gridOrigin.y
                )
                addChild(tile)
                rowArray.append(tile)
            }
            tileMap.append(rowArray)
        }
    }

    var validMoveTargets: Set<String> = []

    func highlightTiles(exactDistance: Int) {
        validMoveTargets.removeAll()

        for row in 0..<numRows {
            for col in 0..<numCols {
                let dx = abs(Int(ballPosition.x) - col)
                let dy = abs(Int(ballPosition.y) - row)

                if dx + dy == exactDistance {
                    let tile = tileMap[row][col]
                    tile.fillColor = .yellow
                    validMoveTargets.insert("tile_\(col)_\(row)")
                } else {
                    tileMap[row][col].fillColor = .green
                }
            }
        }
    }

    func addBall() {
        ballNode = SKShapeNode(circleOfRadius: tileSize / 3)
        ballNode.fillColor = .white
        updateBallPosition()
        addChild(ballNode)
    }

    func updateBallPosition(animated: Bool = false) {
        let newPosition = CGPoint(
            x: ballPosition.x * tileSize + tileSize / 2 + gridOrigin.x,
            y: ballPosition.y * tileSize + tileSize / 2 + gridOrigin.y
        )
        
        if animated {
            let move = SKAction.move(to: newPosition, duration: 0.4)
            ballNode.run(move)
        } else {
            ballNode.position = newPosition
        }
    }

    func addHole() {
        holeNode?.removeFromParent()

        holeNode = SKSpriteNode(imageNamed: "golfPin")
        holeNode.size = CGSize(width: tileSize * 0.9, height: tileSize * 0.9)
        holeNode.position = CGPoint(
            x: holePosition.x * tileSize + tileSize / 2 + gridOrigin.x,
            y: holePosition.y * tileSize + tileSize / 2 + gridOrigin.y
        )
        addChild(holeNode)
    }

    func rollAndMoveBall(direction: CGVector) {
        let roll = Int.random(in: 1...6)

        let newX = Int(ballPosition.x) + Int(direction.dx) * roll
        let newY = Int(ballPosition.y) + Int(direction.dy) * roll

        ballPosition.x = CGFloat(max(0, min(numCols - 1, newX)))
        ballPosition.y = CGFloat(max(0, min(numRows - 1, newY)))

        updateBallPosition()

        if ballPosition == holePosition {
            print("You Win!")
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        for node in tappedNodes {
            if node.name == "Random" {
                node.removeAllActions()
                startRandomNumberAnimation()
                return
            }

            if let name = node.name, validMoveTargets.contains(name) {
                if let components = name.split(separator: "_").dropFirst().compactMap({ Int($0) }) as? [Int], components.count == 2 {
                    let col = components[0]
                    let row = components[1]
                    
                    ballPosition = CGPoint(x: col, y: row)
                    updateBallPosition(animated: true)
                    
                    clearHighlights()
                    restartPulseAnimation()
                }
            }
        }
    }

    func addDirectionButton() {
        let buttonSize = CGSize(width: 50, height: 50)
        let centerX = size.width / 2
        let bottomY: CGFloat = 40

        randomButtonNode = SKSpriteNode(imageNamed: "random")
        randomButtonNode.name = "Random"
        randomButtonNode.size = buttonSize
        randomButtonNode.position = CGPoint(x: centerX, y: bottomY)

        addChild(randomButtonNode)
        restartPulseAnimation()
    }

    func restartPulseAnimation() {
        randomButtonNode.removeAllActions()
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        randomButtonNode.run(SKAction.repeatForever(pulse))
    }

    func addNumberLabel() {
        numberLabel = SKLabelNode(text: "-")
        numberLabel.fontSize = 60
        numberLabel.fontColor = .white
        numberLabel.fontName = "Helvetica-Bold"
        numberLabel.position = CGPoint(x: size.width / 2, y: 100)
        addChild(numberLabel)
    }

    func startRandomNumberAnimation() {
        var elapsedTime: TimeInterval = 0
        let duration: TimeInterval = 3.0
        let interval: TimeInterval = 0.1

        let wait = SKAction.wait(forDuration: interval)
        let update = SKAction.run {
            let randomNumber = Int.random(in: 1...6)
            self.numberLabel.text = "\(randomNumber)"
            elapsedTime += interval
        }

        let sequence = SKAction.sequence([update, wait])
        let loopCount = Int(duration / interval)
        let repeatLoop = SKAction.repeat(sequence, count: loopCount)

        let finish = SKAction.run {
            let finalNumber = Int.random(in: 1...6)
            self.numberLabel.text = "\(finalNumber)"
            self.highlightTiles(exactDistance: finalNumber)
        }

        let fullSequence = SKAction.sequence([repeatLoop, finish])
        numberLabel.run(fullSequence)
    }

    func clearHighlights() {
        for row in tileMap {
            for tile in row {
                tile.fillColor = .green
            }
        }
        validMoveTargets.removeAll()
    }
}
