//
//  GameScene.swift
//  Zombie Conga
//
//  Created by Jimmy Higuchi on 11/16/17.
//  Copyright © 2017 Jimmy Higuchi. All rights reserved.
//

import SpriteKit
import GameplayKit


class GameScene: SKScene {
    
    let playableRect: CGRect
    
    var lastUpdateTime: TimeInterval = 0
    var deltaTime: TimeInterval = 0
    
    var lastTouchLocation: CGPoint?
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var zombieAnimation: SKAction
    
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero
    
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    
    let catMovePointsPerSec:CGFloat = 480.0
    
    var lives = 5
    var gameOver = false
    
    // scene labels
    let livesLabel = SKLabelNode(fontNamed: "Glimstick")
    let catLabel = SKLabelNode(fontNamed: "Glimstick")
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableHeight = size.width/maxAspectRatio
        let playableMargin = (size.height - playableHeight)/2.0
        
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        
        
        var textures: [SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(from view: SKView) {
        backgroundMusicPlayer.stop()
    }
    
    override func didMove(to view: SKView) {
        debugDrawPlayableArea()
        
        playBackgroundMusic(filename: "backgroundMusic.mp3")
    
        let background = SKSpriteNode(imageNamed: "background1")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background.zPosition = -1
        addChild(background)
        
        // add zombie
        
        zombie.position = CGPoint(x: 400 , y: 400)
        addChild(zombie)
        
//        zombie.run(SKAction.repeatForever(zombieAnimation))
        
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(spawnEnemy), SKAction.wait(forDuration: 2.9)])))
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(spawnCat), SKAction.wait(forDuration: 1.0)])))
    
        // lives label
        livesLabel.text = "Lives: \(lives)"
        livesLabel.fontColor = SKColor.black
        livesLabel.fontSize = 100
        livesLabel.zPosition = 100
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .bottom
        livesLabel.position = CGPoint(x: 20, y: size.height/6)
        
        addChild(livesLabel)
        
        // lives label
        catLabel.text = "Cat: 0"
        catLabel.fontColor = SKColor.black
        catLabel.fontSize = 100
        catLabel.zPosition = 100
        catLabel.horizontalAlignmentMode = .right
        catLabel.verticalAlignmentMode = .bottom
        catLabel.position = CGPoint(x: size.width - 20, y: size.height/6)
        
        addChild(catLabel)
        
    }
    
    func checkCollision() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodes(withName: "cat") { node, _ in
            let cat = node as! SKSpriteNode
            if cat.frame.intersects(self.zombie.frame) {
                hitCats.append(cat)
            }
        }
        
        for cat in hitCats {
            print("hit cat")
            zombieHit(sprite: cat)
        }
        
        var hitEnemy: [SKSpriteNode] = []
        enumerateChildNodes(withName: "enemy") { node, _ in
            let enemy = node as! SKSpriteNode
            if enemy.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) {
                hitEnemy.append(enemy)
            }
        }
        
        for enemy in hitEnemy {
            print("hit enemy")
            zombieHit(sprite: enemy)
        }
    }
    
    func zombieHit(sprite: SKSpriteNode) {
        print("** ZOMBIE HIT: \(String(describing: sprite.name)) **")
        if sprite.name == "cat" {
            // sprite.removeFromParent()
            // run(catCollisionSound)
            sprite.name = "train"
            sprite.removeAllActions()
            sprite.setScale(1.0)
            sprite.zRotation = 0
            let turnGreen = SKAction.colorize(with: SKColor.green, colorBlendFactor: 1.0, duration: 0.2)
            sprite.run(turnGreen)
                run(catCollisionSound)
        } else {
            sprite.removeFromParent()
            run(enemyCollisionSound)
            lives -= 1
            
            // additional animation when enemy hit
            let blinkTimes = 10.0
            let duration = 3.0
            let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let slice = duration / blinkTimes
                let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
                node.isHidden = remainder > slice / 2
            }
            let setHidden = SKAction.run() {
                self.zombie.isHidden = false
            }
            
            zombie.run(SKAction.sequence([blinkAction, setHidden]))
            loseCats()
        }
    }
    
    func moveTrain() {
        var trainCount = 0
        var targetPosition = zombie.position
        
        enumerateChildNodes(withName: "train") { node, stop in
            trainCount += 1
            self.catLabel.text = "Cat: \(trainCount)"
            
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.run(moveAction)
            }
            targetPosition = node.position
        }
        if trainCount >= 5 && !gameOver {
            gameOver = true
            print("You win!")
            
            let gameOverScene = GameOverScene(size: size, won: true)
                gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
            
        }
    }
    
    func loseCats() {
        var loseCount = 0
        enumerateChildNodes(withName: "train") { node, stop in
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            
            node.name = ""
            node.run(SKAction.sequence([SKAction.group([SKAction.rotate(byAngle: CGFloat.pi * 4, duration: 1.0),
                                     SKAction.move(to: randomSpot, duration: 1.0),
                                     SKAction.scale(to: 0, duration: 1.0)]),
                                    SKAction.removeFromParent()]))
            
            loseCount += 1
            self.catLabel.text = "Cat: \(loseCount)"
            
            if loseCount >= 2 {
                stop.pointee = true
            }
            
        }
    }
    
    func startZombieAnimation() {
        if zombie.action(forKey: "animation") == nil {
            zombie.run(
                SKAction.repeatForever(zombieAnimation),
                withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
        zombie.removeAction(forKey: "animation")
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        
        enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: CGFloat.random(min: playableRect.minY + enemy.size.width/2, max: playableRect.maxY + enemy.size.width/2))
        addChild(enemy)
        
        let actionMove = SKAction.moveTo(x: -enemy.size.width/2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
        
    }
    
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        
        cat.position = CGPoint(x: CGFloat.random(min: playableRect.minX, max: playableRect.maxX), y: CGFloat.random(min: playableRect.minY, max: playableRect.maxY))
        
        cat.setScale(0)
        addChild(cat)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)
        cat.zRotation = -CGFloat.pi/16.0
        let leftWiggle = SKAction.rotate(byAngle: CGFloat.pi/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence(
            [scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        let wait = SKAction.wait(forDuration: 10)
        let disappear = SKAction.scale(by: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        
        let actions = [appear, groupWait, wait, disappear, removeFromParent]
        cat.run(SKAction.sequence(actions))
    }
    
    func moveZombieToward(_ location: CGPoint) {
        let offset = CGPoint(x: location.x - zombie.position.x, y: location.y - zombie.position.y)
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
        
        velocity = CGPoint(x: direction.x * zombieMovePointsPerSec, y: direction.y * zombieMovePointsPerSec)
        startZombieAnimation()
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = CGPoint(x: velocity.x * CGFloat(deltaTime), y: velocity.y * CGFloat(deltaTime))
        print("Amount to move: \(amountToMove)")
        sprite.position = CGPoint(x: sprite.position.x + amountToMove.x, y: sprite.position.y + amountToMove.y)
        
        // rotate sprite toward touch
        let v1 = CGVector(dx:0, dy:0)
        let v2 = CGVector(dx: velocity.x - position.x, dy: velocity.y - position.y)
        let angle = atan2(v2.dy, v2.dx) - atan2(v1.dy, v1.dx)
        zombie.zRotation = angle
        print("New Angle is: \(angle * CGFloat.pi)")
        
    }
    

  
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let touchLocation = touch.location(in: self)
        lastTouchLocation = touchLocation
        moveZombieToward(touchLocation)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let touchLocation = touch.location(in: self)
        lastTouchLocation = touchLocation
        moveZombieToward(touchLocation)
    }
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: playableRect.minX, y: playableRect.minY)
        let topRight = CGPoint(x: playableRect.maxX, y: playableRect.maxY)
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            deltaTime = currentTime - lastUpdateTime
        } else {
            deltaTime = 0
        }
        lastUpdateTime = currentTime
        print("\(deltaTime*1000) milliseconds since last update")
        
        // actual movement of zombie
        if let lastTouchLocation = lastTouchLocation {
            let diff = lastTouchLocation - zombie.position
            
            if (diff.length() <= zombieMovePointsPerSec * CGFloat(deltaTime)) {
                zombie.position = lastTouchLocation
                velocity = CGPoint.zero
                stopZombieAnimation()
            } else {
                moveSprite(sprite: zombie, velocity: velocity)
                
            }
        }
        boundsCheckZombie()
        moveTrain()
        
        // checking if game is over
        if lives <= 0 && !gameOver {
            gameOver = true
            print("You Lose!!!")
            
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    override func didEvaluateActions() {
        checkCollision()
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
}
