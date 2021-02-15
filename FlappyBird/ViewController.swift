//
//  ViewController.swift
//  FlappyBird
//
//  Created by 中川Air利光 on 2021/02/10.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // SKViewにかたを変換する
        let skView = self.view as! SKView
        
        // FPSを表示する
        skView.showsFPS = true

        // ノードの数を表示する
        skView.showsNodeCount = true
        
        // ビューと同じサイズでシーンを作成する
//        let scene = SKScene(size:skView.frame.size)   // ↓に変更する前のコード
        let scene = GameScene(size:skView.frame.size)   // GameSceneクラスに変更する

        //ビューにシーンを表示する
        skView.presentScene(scene)
        
    }
    
    // ステータスバーを消す --- ここから ---
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }   // --- ここまで追加 ---

}

