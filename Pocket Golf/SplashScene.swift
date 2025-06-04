//
//  SplashScene.swift
//  Pocket Golf
//
//  Created by Christian Farls on 6/4/25.
//

import SwiftUI
import SpriteKit

struct SplashSceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        let scene = SplashScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        return skView
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        // Leave empty for preview
    }
}

class SplashScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .white

        let centerX = size.width / 2
        let centerY = size.height / 2
        let objectSize = size.height * 0.10
        let ballStartOffset = size.width * 0.30

        // Golf Club
        let golfClub = SKSpriteNode(imageNamed: "golfClub")
        golfClub.size = CGSize(width: objectSize, height: objectSize)
        golfClub.position = CGPoint(x: centerX - ballStartOffset, y: centerY - objectSize)
        addChild(golfClub)

        // Golf Hole
        let hole = SKSpriteNode(imageNamed: "golfHole")
        hole.size = CGSize(width: objectSize * 0.6, height: objectSize * 0.6)
        hole.position = CGPoint(x: centerX + ballStartOffset, y: centerY - objectSize * 1.35)
        hole.zPosition = 0
        addChild(hole)

        // Golf Ball
        let golfBall = SKSpriteNode(imageNamed: "golfBall")
        golfBall.size = CGSize(width: objectSize * 0.3, height: objectSize * 0.3)
        golfBall.position = CGPoint(x: centerX - ballStartOffset / 1.15, y: centerY - objectSize * 1.2)
        golfBall.zPosition = 1
        addChild(golfBall)

        // Flag (not used yet, but included for future animation)
        let flag = SKSpriteNode(imageNamed: "golfPin")
        flag.size = CGSize(width: objectSize * 0.8, height: objectSize * 0.8)
        flag.position = hole.position
        flag.setScale(0)
        addChild(flag)

        // Title
        let title = SKLabelNode(text: "Pocket Golf")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = size.height * 0.06
        title.fontColor = .black
        title.position = CGPoint(x: centerX, y: centerY + objectSize)
        title.alpha = 0
        addChild(title)

        // Delay 1 second before starting animations
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run {
                self.startAnimations(
                    golfClub: golfClub,
                    golfBall: golfBall,
                    hole: hole,
                    title: title
                )
            }
        ]))
    }

    func startAnimations(golfClub: SKSpriteNode, golfBall: SKSpriteNode, hole: SKSpriteNode, title: SKLabelNode) {
        // Club swing
        let swingBack = SKAction.rotate(byAngle: -.pi / 6, duration: 1.0)
        let swingFront = SKAction.rotate(byAngle: .pi / 3, duration: 0.2)

        // Ball animation: move -> wait -> fall -> disappear
        let moveAboveHole = SKAction.move(to: CGPoint(x: hole.position.x, y: hole.position.y + 13), duration: 0.6)
        moveAboveHole.timingMode = .easeInEaseOut

        let pauseAboveHole = SKAction.wait(forDuration: 0.5)

        let fallDown = SKAction.move(to: hole.position, duration: 0.4)
        let scaleDown = SKAction.scale(to: 0.0, duration: 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        let disappear = SKAction.group([fallDown, scaleDown, fadeOut])

        let showTitle = SKAction.run {
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            title.run(fadeIn)
        }

        let remove = SKAction.removeFromParent()

        let ballSequence = SKAction.sequence([
            moveAboveHole,
            pauseAboveHole,
            showTitle,
            disappear,
            remove
        ])

        // Start ball animation 0.1 seconds into swingFront
        let delayToMidSwingFront = SKAction.wait(forDuration: 0.1)
        let startBall = SKAction.run {
            golfBall.run(ballSequence)
        }
        let triggerBallMidSwing = SKAction.sequence([delayToMidSwingFront, startBall])

        // Run swing front and trigger ball in parallel
        let swingFrontWithBall = SKAction.group([
            swingFront,
            triggerBallMidSwing
        ])

        let fullSwing = SKAction.sequence([
            swingBack,
            swingFrontWithBall
        ])

        golfClub.run(fullSwing)

        // Transition to GameScene
        let transition = SKAction.run {
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            self.view?.presentScene(gameScene, transition: SKTransition.fade(withDuration: 1.0))
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5), // Delay while app starts
            SKAction.wait(forDuration: 1.0), // Delay after animation, before game loads
            transition
        ]))
    }
}

#Preview {
    SplashSceneView()
}
