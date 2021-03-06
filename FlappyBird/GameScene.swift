//
//  GameScene.swift
//  FlappyBird
//
//  Created by 中川Air利光 on 2021/02/10.
//

import UIKit
import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!          // 追加
    var itemNode:SKNode!            // 課題用に追加
    var baditemNode:SKNode!         // 課題用に追加
    var deathitemNode:SKNode!       // 課題用に追加
    var staritemNode:SKNode!        // 課題用に追加

    var bgmPlayer:AVAudioPlayer!        // BGM
    var itemPlayer:AVAudioPlayer!       // アイテム取得時効果音
    var baditemPlayer:AVAudioPlayer!    // マイナスアイテム取得時効果音
    var clashPlayer:AVAudioPlayer!      // 衝突時効果音
    var staritemPlayer:AVAudioPlayer!   // スコアアップアイテム取得時効果音

    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0           // 0...00000001
    let groundCategory: UInt32 = 1 << 1         // 0...00000010
    let wallCategory: UInt32 = 1 << 2           // 0...00000100
    let scoreCategory: UInt32 = 1 << 3          // 0...00001000
    let itemScoreCategory: UInt32 = 1 << 4      // 0...00010000
    let baditemScoreCategory: UInt32 = 1 << 5   // 0...00100000
    let deathitemScoreCategory: UInt32 = 1 << 6 // 0...01000000
    let staritemScoreCategory: UInt32 = 1 << 7  // 0...10000000

    // 難易度
    var gameLevel = 1                           // ゲームレベル（0:Eazy / 1:Normal / 2〜:Hard）
    // DEBUG制御
    var debug_flg = 0                           // DEBUGフラグ（0:通常プレイ / 1:衝突しても続行）
    
    // スコア用
    var score = 0                               // スコア、追加
    var itemScore = 0                           // アイテムスコア、課題用に追加
    var scoreLabelNode:SKLabelNode!             // 追加
    var bestScoreLabelNode:SKLabelNode!         // 追加
    var itemScoreLabelNode:SKLabelNode!         // 課題用に追加
    var msgLabelNode:SKLabelNode!               // 追加
    let userDefaults:UserDefaults = UserDefaults.standard
    
    // SKView上にシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {

        // アイテム取得時効果音ファイルを指定する
        let itemSoundURL = Bundle.main.url(forResource: "itemget", withExtension: "mp3")
        do {
            // アイテム取得効果音を鳴らす
            itemPlayer = try AVAudioPlayer(contentsOf: itemSoundURL!)
        } catch {
            print("Item Sound Error...")
        }

        // BGMを指定する
        let bgmSoundURL = Bundle.main.url(forResource: "bgm1", withExtension: "MP3")
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: bgmSoundURL!)
            bgmPlayer.numberOfLoops = -1    // BGM再生ループは無限
            bgmPlayer?.play()               // BGMを再生開始
        } catch {
            print("Main BGM Error...")
        }

        // 衝突時効果音を鳴らす
        let clashSoundURL = Bundle.main.url(forResource: "bad", withExtension: "mp3")
        do {
            clashPlayer = try AVAudioPlayer(contentsOf: clashSoundURL!)
        } catch {
            print("Clash Sound Error...")
        }

        // マイナスアイテム取得時効果音を鳴らす
        let baditemSoundURL = Bundle.main.url(forResource: "baditem", withExtension: "mp3")
        do {
            baditemPlayer = try AVAudioPlayer(contentsOf: baditemSoundURL!)
        } catch {
            print("Clash Sound Error...")
        }

        // スコアアップアイテム取得時効果音を鳴らす
        let staritemSoundURL = Bundle.main.url(forResource: "star", withExtension: "mp3")
        do {
            staritemPlayer = try AVAudioPlayer(contentsOf: staritemSoundURL!)
        } catch {
            print("ScoreUp Sound Error...")
        }

        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)  // 追加
        physicsWorld.contactDelegate = self             // 追加
        
        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
 
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用のノード
        wallNode = SKNode()             //追加
        scrollNode.addChild(wallNode)   // 追加
     
        // アイテム用のノード：課題用に追加    --- ここから ---
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        baditemNode = SKNode()
        scrollNode.addChild(baditemNode)
        deathitemNode = SKNode()
        scrollNode.addChild(deathitemNode)
        staritemNode = SKNode()
        scrollNode.addChild(staritemNode)
        // --- ここまで ---
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()       //
        setupCloud()        //
        setupWall()         // 追加
        setupBird()         // 追加
        setupItem()         // 課題用に追加
        setupbadItem()      // 課題用に追加
        setupdeathItem()    // 課題用に追加
        setupstarItem()     // 課題用に追加
        setupScoreLabel()   // 追加
    }
    
    // SKPhysicsContactDelegateのメソッド。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突(壁の隙間を通過)した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"      // 追加
            
            // ベストスコア更新か確認する --- ここから ---
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"     // 追加
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }   // --- ここまで ---
        } else if (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory || (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory {
            // アイテムに衝突した
            print("ItemGet")
            itemScore += 1
            itemScoreLabelNode.text = "Item Score:\(itemScore)"
            
            itemPlayer?.play()
            
            if (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory {
                contact.bodyA.node?.removeFromParent()
            }
            if (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory {
                contact.bodyB.node?.removeFromParent()
            }
        } else if (contact.bodyA.categoryBitMask & staritemScoreCategory) == staritemScoreCategory || (contact.bodyB.categoryBitMask & staritemScoreCategory) == staritemScoreCategory {
            // スコアアップアイテムに衝突した
            print("starItemGet")
            itemScore += 1
            score += 2
            scoreLabelNode.text = "Score:\(score)"      // 追加
            itemScoreLabelNode.text = "Item Score:\(itemScore)"
            
            staritemPlayer?.play()
            
            if (contact.bodyA.categoryBitMask & staritemScoreCategory) == staritemScoreCategory {
                contact.bodyA.node?.removeFromParent()
            }
            if (contact.bodyB.categoryBitMask & staritemScoreCategory) == staritemScoreCategory {
                contact.bodyB.node?.removeFromParent()
            }
        } else if (contact.bodyA.categoryBitMask & baditemScoreCategory) == baditemScoreCategory || (contact.bodyB.categoryBitMask & baditemScoreCategory) == baditemScoreCategory {
            // マイナスアイテムに衝突した
            print("badItemGet")
            if itemScore > 0 {
                itemScore -= 1
            }
            itemScoreLabelNode.text = "Item Score:\(itemScore)"
            
            baditemPlayer?.play()
            
            if (contact.bodyA.categoryBitMask & baditemScoreCategory) == baditemScoreCategory {
                contact.bodyA.node?.removeFromParent()
            }
            if (contact.bodyB.categoryBitMask & baditemScoreCategory) == baditemScoreCategory {
                contact.bodyB.node?.removeFromParent()
            }
        } else {
            // 壁か地面と衝突したか、即死アイテム取得
            clashPlayer?.play()     // 衝突時効果音再生
            if debug_flg == 1 {
                return
            }
            bgmPlayer?.stop()       // BGMの再生を停止
            // gameoverのBGMを鳴らす
            let bgmSoundURL = Bundle.main.url(forResource: "gameover", withExtension: "MP3")
            do {
                bgmPlayer = try AVAudioPlayer(contentsOf: bgmSoundURL!)
                bgmPlayer?.play()   // ゲームオーバー時の曲を再生
            } catch {
                print("GameOver Sound Error...")
            }

            msgLabelNode.text = "GAME OVER" // 画面中央にゲームオーバー表示
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    func restart() {
        score = 0
        itemScore = 0
        
        // BGMを鳴らす
        let bgmSoundURL = Bundle.main.url(forResource: "bgm1", withExtension: "MP3")
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: bgmSoundURL!)
            bgmPlayer.numberOfLoops = -1
            bgmPlayer?.play()
        } catch {
            print("Main BGM Error...")
        }
        
        scoreLabelNode.text = "Score:\(score)"      // 追加
        itemScoreLabelNode.text = "ItemScore:\(itemScore)"   // 課題用に追加
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0

        msgLabelNode.text = ""

        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest  // 処理速度を優先(画質優先：.linear)
        
        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2

        // スクロールするアクションを作成
        // 左方向に画像を一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)

        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))

        // テクスチャを指定してスプライトを作成する
        //let groundSprite = SKSpriteNode(texture: groundTexture)
        
        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            
            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            // スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory        // 追加
            
            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false   // 追加
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        // スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y:0, duration: 20)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする

            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        var gap:Int = 0
        var swing:Float = 0.0
        
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y:0, duration:4)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // ２つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()

        if gameLevel == 0 {     // イージーモード？
            gap = 4
            swing = 3.5
        } else {                // ノーマル＆ハードモード？
            gap = 3
            swing = 2.5
        }
        
        // 鳥が通り抜ける隙間の長さを鳥のサイズの３倍とする
//        let slit_length = birdSize.height * 3
        let slit_length = birdSize.height * CGFloat(gap)
        // 隙間位置の上下の振れ幅を鳥のサイズの2.5倍とする
//        let random_y_range = birdSize.height * 2.5
        let random_y_range = birdSize.height * CGFloat(swing)

        // 下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        // 壁を精製するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50    // 雲より手前、地面より奥
            
            // 0〜random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            // スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())      // 追加
            under.physicsBody?.categoryBitMask = self.wallCategory                  // 追加
            
            // 衝突の時に動かないように設定する
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            // 上側の壁を生成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)

            // スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())      // 追加
            upper.physicsBody?.categoryBitMask = self.wallCategory                  // 追加
            
            // 衝突の時動かないように設定する
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            // スコアアップ用のノード --- ここから ---
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            // --- ここまで ---
            
            wall.run(wallAnimation)
            self.wallNode.addChild(wall)
        })
        
        // 次の「壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)  // 追加

        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false    // 追加
        
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory        // 追加
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory      // 追加
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory    // 追加
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加する
        addChild(bird)
    }
    
    func setupItem() {
        // アイテムの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "i_ringo.gif")
        itemTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width * 2)
        
        // 画面外まで移動するアクションを作成
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
        
        // 自身を消すアクションを作成
        let removeItem = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        // アイテムを作成するアクションを作成
        let createItemAnimation = SKAction.run({
            // アイテム関連のノードを乗せるノード作成
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y:0.0)
            
            // 画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            
            // アイテムのY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 2
            
            // アイテムのY軸の下限
            let item_lowest_y = UInt32( center_y - itemTexture.size().height / 2 - random_y_range / 2)
            
            // 1〜random_y_rangeまでのランダムな数値を生成
            let random_y = arc4random_uniform( UInt32(random_y_range))
            
            // Y軸の加減にランダムな値を足して、アイテムのY座標を決定
            let item_y = CGFloat(item_lowest_y + random_y)
            
            // 画面のX軸の中央値
            let center_x = self.frame.size.width / 2
            
            // アイテムのX座標を上下ランダムにさせる時の最大値
            let random_x_range = self.frame.size.width / 2
            
            // アイテムのX軸の下限
            let item_lowest_x = UInt32( center_x - itemTexture.size().width / 2 - random_x_range / 2)
            
            // 1〜randam_x_rangeまでのランダムな整数を生成
            let random_x = arc4random_uniform( UInt32(random_x_range))

            // X軸の加減にランダムな値を足して、アイテムのX座標を決定
            let item_x = CGFloat(item_lowest_x + random_x)
            
            // アイテムを生成
            let itemSprite = SKSpriteNode(texture: itemTexture)
            itemSprite.position = CGPoint(x: item_x, y: item_y)
            
            itemSprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: itemSprite.size.width, height: itemSprite.size.height))   //重力を設定
            itemSprite.physicsBody?.isDynamic = false
            itemSprite.physicsBody?.categoryBitMask = self.itemScoreCategory
            itemSprite.physicsBody?.contactTestBitMask = self.birdCategory      // 衝突判定させる相手のカテゴリ設定
            
            item.addChild(itemSprite)
            
            item.run(itemAnimation)
            
            self.itemNode.addChild(item)
        })
        
        // 次のアイテム作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // アイテムを作成->待ち時間->アイテムを作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation, waitAnimation]))
        
        itemNode.run(repeatForeverAnimation)
    }

    func setupbadItem() {
        var badItemwait:Int = 0
        
        // アイテムの画像を読み込む
        let baditemTexture = SKTexture(imageNamed: "i_imokm.gif")
        baditemTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width * 2)
        
        // 画面外まで移動するアクションを作成
        let movebadItem = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
        
        // 自身を消すアクションを作成
        let removebadItem = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let baditemAnimation = SKAction.sequence([movebadItem, removebadItem])
        
        // アイテムを作成するアクションを作成
        let createbadItemAnimation = SKAction.run({
            // アイテム関連のノードを乗せるノード作成
            let baditem = SKNode()
            baditem.position = CGPoint(x: self.frame.size.width + baditemTexture.size().width / 2, y:0.0)
            
            // 画面のY軸の中央値
            let badcenter_y = self.frame.size.height / 2
            
            // アイテムのY座標を上下ランダムにさせるときの最大値
            let badrandom_y_range = self.frame.size.height / 2
            
            // アイテムのY軸の下限
            let baditem_lowest_y = UInt32( badcenter_y - baditemTexture.size().height / 2 - badrandom_y_range / 2)
            
            // 1〜random_y_rangeまでのランダムな数値を生成
            let badrandom_y = arc4random_uniform( UInt32(badrandom_y_range))
            
            // Y軸の加減にランダムな値を足して、アイテムのY座標を決定
            let baditem_y = CGFloat(baditem_lowest_y + badrandom_y)
            
            // 画面のX軸の中央値
            let badcenter_x = self.frame.size.width / 2
            
            // アイテムのX座標を上下ランダムにさせる時の最大値
            let badrandom_x_range = self.frame.size.width / 2
            
            // アイテムのX軸の下限
            let baditem_lowest_x = UInt32( badcenter_x - baditemTexture.size().width / 2 - badrandom_x_range / 2)
            
            // 1〜randam_x_rangeまでのランダムな整数を生成
            let badrandom_x = arc4random_uniform( UInt32(badrandom_x_range))

            // X軸の加減にランダムな値を足して、アイテムのX座標を決定
            let baditem_x = CGFloat(baditem_lowest_x + badrandom_x)
            
            // アイテムを生成
            let baditemSprite = SKSpriteNode(texture: baditemTexture)
            baditemSprite.position = CGPoint(x: baditem_x, y: baditem_y)
            
            baditemSprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: baditemSprite.size.width, height: baditemSprite.size.height))   //重力を設定
            baditemSprite.physicsBody?.isDynamic = false
            baditemSprite.physicsBody?.categoryBitMask = self.baditemScoreCategory
            baditemSprite.physicsBody?.contactTestBitMask = self.birdCategory      // 衝突判定させる相手のカテゴリ設定
            
            baditem.addChild(baditemSprite)
            
            baditem.run(baditemAnimation)
            
            self.baditemNode.addChild(baditem)
        })
        
        // 次のアイテム作成までの待ち時間のアクションを作成
        if gameLevel == 0 {             // イージーモード？
            badItemwait = 10
        } else if gameLevel == 2 {      // ハードモード？
            badItemwait = 2
        } else {
            badItemwait = 5             // ノーマルモード？
        }
        let badwaitAnimation = SKAction.wait(forDuration: TimeInterval(CGFloat(badItemwait)))
        // アイテムを作成->待ち時間->アイテムを作成を無限に繰り返すアクションを作成
        let badrepeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createbadItemAnimation, badwaitAnimation]))
        baditemNode.run(badrepeatForeverAnimation)
    }

    func setupdeathItem() {
        var deathItemwait:Int = 0
        
        // アイテムの画像を読み込む
        let deathitemTexture = SKTexture(imageNamed: "i_imop.gif")
        deathitemTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width * 2)
        
        // 画面外まで移動するアクションを作成
        let movedeathItem = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
        
        // 自身を消すアクションを作成
        let removedeathItem = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let deathitemAnimation = SKAction.sequence([movedeathItem, removedeathItem])
        
        // アイテムを作成するアクションを作成
        let createdeathItemAnimation = SKAction.run({
            // アイテム関連のノードを乗せるノード作成
            let deathitem = SKNode()
            deathitem.position = CGPoint(x: self.frame.size.width + deathitemTexture.size().width / 2, y:0.0)
            
            // 画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            
            // アイテムのY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 2
            
            // アイテムのY軸の下限
            let deathitem_lowest_y = UInt32( center_y - deathitemTexture.size().height / 2 - random_y_range / 2)
            
            // 1〜random_y_rangeまでのランダムな数値を生成
            let random_y = arc4random_uniform( UInt32(random_y_range))
            
            // Y軸の加減にランダムな値を足して、アイテムのY座標を決定
            let deathitem_y = CGFloat(deathitem_lowest_y + random_y)
            
            // 画面のX軸の中央値
            let deathcenter_x = self.frame.size.width / 2
            
            // アイテムのX座標を上下ランダムにさせる時の最大値
            let deathrandom_x_range = self.frame.size.width / 2
            
            // アイテムのX軸の下限
            let deathitem_lowest_x = UInt32( deathcenter_x - deathitemTexture.size().width / 2 - deathrandom_x_range / 2)
            
            // 1〜randam_x_rangeまでのランダムな整数を生成
            let deathrandom_x = arc4random_uniform( UInt32(deathrandom_x_range))

            // X軸の加減にランダムな値を足して、アイテムのX座標を決定
            let deathitem_x = CGFloat(deathitem_lowest_x + deathrandom_x)
            
            // アイテムを生成
            let deathitemSprite = SKSpriteNode(texture: deathitemTexture)
            deathitemSprite.position = CGPoint(x: deathitem_x, y: deathitem_y)
            
            deathitemSprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: deathitemSprite.size.width, height: deathitemSprite.size.height))   //重力を設定
            deathitemSprite.physicsBody?.isDynamic = false
            deathitemSprite.physicsBody?.categoryBitMask = self.deathitemScoreCategory
            deathitemSprite.physicsBody?.contactTestBitMask = self.birdCategory      // 衝突判定させる相手のカテゴリ設定
            
            deathitem.addChild(deathitemSprite)
            
            deathitem.run(deathitemAnimation)
            
            self.deathitemNode.addChild(deathitem)
        })
        
        // 次のアイテム作成までの待ち時間のアクションを作成
        if gameLevel == 0 {             // イージーモード？
            deathItemwait = 86400        // 実質即死アイテムは出さない
        } else if gameLevel == 2 {      // ハードモード？
            deathItemwait = 10
        } else {
            deathItemwait = 30             // ノーマルモード？
        }
//        let deathwaitAnimation = SKAction.wait(forDuration: 7)
        let deathwaitAnimation = SKAction.wait(forDuration: TimeInterval(CGFloat(deathItemwait)))

        // アイテムを作成->待ち時間->アイテムを作成を無限に繰り返すアクションを作成
        let deathrepeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createdeathItemAnimation, deathwaitAnimation]))
            
        deathitemNode.run(deathrepeatForeverAnimation)
    }
    
    func setupstarItem() {
        var starItemwait:Int = 0
        
        // アイテムの画像を読み込む
        let staritemTexture = SKTexture(imageNamed: "i_hosi.gif")
        staritemTexture.filteringMode = .linear
        
        // 移動する距離を計算
        let starmovingDistance = CGFloat(self.frame.size.width * 2)
        
        // 画面外まで移動するアクションを作成
        let starmoveItem = SKAction.moveBy(x: -starmovingDistance, y: 0, duration:4.0)
        
        // 自身を消すアクションを作成
        let starremoveItem = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let staritemAnimation = SKAction.sequence([starmoveItem, starremoveItem])
        
        // アイテムを作成するアクションを作成
        let starcreateItemAnimation = SKAction.run({
            // アイテム関連のノードを乗せるノード作成
            let staritem = SKNode()
            staritem.position = CGPoint(x: self.frame.size.width + staritemTexture.size().width / 2, y:0.0)
            
            // 画面のY軸の中央値
            let starcenter_y = self.frame.size.height / 2
            
            // アイテムのY座標を上下ランダムにさせるときの最大値
            let starrandom_y_range = self.frame.size.height / 2
            
            // アイテムのY軸の下限
            let staritem_lowest_y = UInt32( starcenter_y - staritemTexture.size().height / 2 - starrandom_y_range / 2)
            
            // 1〜random_y_rangeまでのランダムな数値を生成
            let starrandom_y = arc4random_uniform( UInt32(starrandom_y_range))
            
            // Y軸の加減にランダムな値を足して、アイテムのY座標を決定
            let staritem_y = CGFloat(staritem_lowest_y + starrandom_y)
            
            // 画面のX軸の中央値
            let starcenter_x = self.frame.size.width / 2
            
            // アイテムのX座標を上下ランダムにさせる時の最大値
            let starrandom_x_range = self.frame.size.width / 2
            
            // アイテムのX軸の下限
            let staritem_lowest_x = UInt32( starcenter_x - staritemTexture.size().width / 2 - starrandom_x_range / 2)
            
            // 1〜randam_x_rangeまでのランダムな整数を生成
            let starrandom_x = arc4random_uniform( UInt32(starrandom_x_range))

            // X軸の加減にランダムな値を足して、アイテムのX座標を決定
            let staritem_x = CGFloat(staritem_lowest_x + starrandom_x)
            
            // アイテムを生成
            let staritemSprite = SKSpriteNode(texture: staritemTexture)
            staritemSprite.position = CGPoint(x: staritem_x, y: staritem_y)
            
            staritemSprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: staritemSprite.size.width, height: staritemSprite.size.height))   //重力を設定
            staritemSprite.physicsBody?.isDynamic = false
            staritemSprite.physicsBody?.categoryBitMask = self.staritemScoreCategory
            staritemSprite.physicsBody?.contactTestBitMask = self.birdCategory      // 衝突判定させる相手のカテゴリ設定
            
            staritem.addChild(staritemSprite)
            
            staritem.run(staritemAnimation)
            
            self.staritemNode.addChild(staritem)
        })
        
        if gameLevel == 0 {             // イージーモード？
            starItemwait = 15           //
        } else if gameLevel == 2 {      // ハードモード？
            starItemwait = 60
        } else {
            starItemwait = 30            // ノーマルモード？
        }
        let starwaitAnimation = SKAction.wait(forDuration: TimeInterval(CGFloat(starItemwait)))
        
        // アイテムを作成->待ち時間->アイテムを作成を無限に繰り返すアクションを作成
        let starrepeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([starcreateItemAnimation, starwaitAnimation]))
        
        staritemNode.run(starrepeatForeverAnimation)
    }


    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100  // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100  // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "BEST Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)

        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100  // 一番手前に表示する
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score:\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
        msgLabelNode = SKLabelNode(fontNamed: "Gurmukhi Sangam MN")             // 追加
        msgLabelNode.fontColor = UIColor.red
        msgLabelNode.fontSize = 50
        msgLabelNode.position = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2 )
        msgLabelNode.zPosition = 100  // 一番手前に表示する
        msgLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        msgLabelNode.text = ""
        self.addChild(msgLabelNode)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {       // 追加
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero

            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {     // --- ここから ---
            restart()
        }   // --- ここまで ---
    }
}
