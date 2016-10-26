//
//  ViewController.swift
//  memo
//
//  Created by Ryuki on 2016/10/12.
//  Copyright © 2016 Ryuki. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate  {
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var canvasView: UIImageView!

  //ViewController.isUserInteractionEnabled = true
 
  var lastPoint: CGPoint?                 //直前のタッチ座標の保存用
  
  var lineWidth: CGFloat?                 //描画用の線の太さの保存用
  var drawColor = UIColor.black              //描画色の保存用
  //var bezierPath = UIBezierPath()         //お絵描きに使用
  var bezierPath: UIBezierPath?             // お絵描き用に使用　変数宣言のみしておく
  let defaultLineWidth: CGFloat = 10.0    //デフォルトの線の太さ
  var myGreenSlider = UISlider() //スライダー定義


  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    scrollView.delegate = self
    scrollView.minimumZoomScale = 1.0                   // 最小拡大率
    scrollView.maximumZoomScale = 4.0                   // 最大拡大率
    scrollView.zoomScale = 1.0                          // 表示時の拡大率(初期値)
    
    prepareDrawing()                                    //お絵描き準備
    
    initSlider()
    
  }

    func initSlider() {
        
        // Sliderを作成する.
        myGreenSlider = UISlider(frame: CGRect(x:0, y:0, width:self.view.frame.width - 20, height:30))
        myGreenSlider.layer.position = CGPoint(x:self.view.frame.midX, y:self.view.frame.height-65)
        //myGreenSlider.backgroundColor = UIColor.whit
        //myGreenSlider.layer.cornerRadius = 10.0
        //myGreenSlider.layer.shadowOpacity = 0.5
        //myGreenSlider.layer.masksToBounds = false
        myGreenSlider.isHidden = true
        self.view.setNeedsDisplay()
        self.view.addSubview(myGreenSlider)
        // 最小値と最大値を設定する.
        myGreenSlider.minimumValue = 0.2
        myGreenSlider.maximumValue = 1
        
        // Sliderの位置を設定する.
        myGreenSlider.value = 0.5
        
    }
    
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  

  /**
   拡大縮小に対応
   */
  private func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
    return self.canvasView
  }
  
  
  /**
   キャンバスの準備 (何も描かれていないUIImageの作成)
   */
  func prepareCanvas() {
    let canvasSize = CGSize(width: view.frame.width * 2, height: view.frame.height * 2)     //キャンバスのサイズの決定
    let canvasRect = CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)      //キャンバスのRectの決定
    UIGraphicsBeginImageContextWithOptions(canvasSize, false, 0.0)              //コンテキスト作成(キャンバスのUIImageを作成する為)
    var firstCanvasImage = UIImage()                                            //キャンバス用UIImage(まだ空っぽ)
    UIColor.white.setFill()                                              //白色塗りつぶし作業1
    UIRectFill(canvasRect)                                                      //白色塗りつぶし作業2
    firstCanvasImage.draw(in: canvasRect)                                     //firstCanvasImageの内容を描く(真っ白)
    firstCanvasImage = UIGraphicsGetImageFromCurrentImageContext()!              //何も描かれてないUIImageを取得
    canvasView.contentMode = .scaleAspectFit                                    //contentModeの設定
    canvasView.image = firstCanvasImage                                         //画面の表示を更新
    UIGraphicsEndImageContext()                                                 //コンテキストを閉じる
  }
  
  

  /**
   UIGestureRecognizerでお絵描き対応。1本指でなぞった時のみの対応とする。
   */
  private func prepareDrawing() {
    
    //実際のお絵描きで言う描く手段(色えんぴつ？クレヨン？絵の具？など)の準備
    let myDraw = UIPanGestureRecognizer(target: self, action: #selector(ViewController.drawGesture(_:)))
    myDraw.maximumNumberOfTouches = 1
    self.scrollView.addGestureRecognizer(myDraw)
    
    //実際のお絵描きで言うキャンバスの準備 (=何も描かれていないUIImageの作成)
    prepareCanvas()
    
  }
  
  /**
   draw動作
   */
  func drawGesture(_ sender: AnyObject) {
    
    guard let drawGesture = sender as? UIPanGestureRecognizer else {
      print("drawGesture Error happened.")
      return
    }
    
    guard let canvas = self.canvasView.image else {
      fatalError("self.pictureView.image not found")
    }
    
    
    let touchPoint = drawGesture.location(in: canvasView)         //タッチ座標を取得
    
    switch drawGesture.state {
    case .began:
      bezierPath = UIBezierPath()               //書くたびに被せていく
      lastPoint = touchPoint                                      //タッチ座標をlastTouchPointとして保存する
   
      
      //touchPointの座標はscrollView基準なのでキャンバスの大きさに合わせた座標に変換しなければいけない
      //LastPointをキャンバスサイズ基準にConvert
      let lastPointForCanvasSize = convertPointForCanvasSize(originalPoint: lastPoint!, canvasSize: canvas.size)
      
      bezierPath?.lineCapStyle = .round                            //描画線の設定 端を丸くする
      bezierPath?.lineWidth = defaultLineWidth * CGFloat(myGreenSlider.value)                 //描画線の太さ
      bezierPath?.move(to: lastPointForCanvasSize)
      
    case .changed:
      
      let newPoint = touchPoint                                   //タッチポイントを最新として保存
      
      //Draw実行
      let imageAfterDraw = drawGestureAtChanged(canvas: canvas, lastPoint: lastPoint!, newPoint: newPoint, bezierPath: bezierPath!)
      self.canvasView.image = imageAfterDraw                      //Draw画像をCanvasに上書き
      lastPoint = newPoint                                        //Point保存
      
    case .ended:
      print("Finish dragging")
      
    default:
      ()
    }
    
  }
  
  
  
  /**
   UIGestureRecognizerのStatusが.Changedの時に実行するDraw動作
   
   - parameter canvas : キャンバス
   - parameter lastPoint : 最新のタッチから直前に保存した座標
   - parameter newPoint : 最新のタッチの座標座標
   - parameter bezierPath : 線の設定などが保管されたインスタンス
   - returns : 描画後の画像
   */
  func drawGestureAtChanged(canvas: UIImage, lastPoint: CGPoint, newPoint: CGPoint, bezierPath: UIBezierPath) -> UIImage {
    
    //最新のtouchPointとlastPointからmiddlePointを算出
    let middlePoint = CGPoint( x: (lastPoint.x + newPoint.x) / 2, y: (lastPoint.y + newPoint.y) / 2)
    
    //各ポイントの座標はscrollView基準なのでキャンバスの大きさに合わせた座標に変換しなければいけない
    //各ポイントをキャンバスサイズ基準にConvert
    let middlePointForCanvas = convertPointForCanvasSize(originalPoint: middlePoint, canvasSize: canvas.size)
    let lastPointForCanvas   = convertPointForCanvasSize(originalPoint: lastPoint, canvasSize: canvas.size)
    
    bezierPath.addQuadCurve(to: middlePointForCanvas, controlPoint: lastPointForCanvas)  //曲線を描く
    UIGraphicsBeginImageContextWithOptions(canvas.size, false, 0.0)                 //コンテキストを作成
    let canvasRect = CGRect(x:0, y:0, width:canvas.size.width, height:canvas.size.height)        //コンテキストのRect
    self.canvasView.image?.draw(in: canvasRect)                                   //既存のCanvasを準備
    drawColor.setStroke()                                                           //drawをセット
    bezierPath.stroke()                                                             //draw実行
    let imageAfterDraw = UIGraphicsGetImageFromCurrentImageContext()                //Draw後の画像
    UIGraphicsEndImageContext()                                                     //コンテキストを閉じる
    
    return imageAfterDraw!
  }
  

  func convertPointForCanvasSize(originalPoint: CGPoint, canvasSize: CGSize) -> CGPoint {
    
    let viewSize = scrollView.frame.size
    var ajustContextSize = canvasSize
    var diffSize: CGSize = CGSize(width:0, height:0)
    let viewRatio = viewSize.width / viewSize.height
    let contextRatio = canvasSize.width / canvasSize.height
    let isWidthLong = viewRatio < contextRatio ? true : false
    
    if isWidthLong {
      
      ajustContextSize.height = ajustContextSize.width * viewSize.height / viewSize.width
      diffSize.height = (ajustContextSize.height - canvasSize.height) / 2
      
    } else {
      
      ajustContextSize.width = ajustContextSize.height * viewSize.width / viewSize.height
      diffSize.width = (ajustContextSize.width - canvasSize.width) / 2
      
    }
    
    let convertPoint = CGPoint(x: originalPoint.x * ajustContextSize.width / viewSize.width - diffSize.width,
                               y: originalPoint.y * ajustContextSize.height / viewSize.height - diffSize.height)
    
    
    return convertPoint
    
  }
    
    // 青ボタン追加
    @IBAction func selectBlue(_ sender: AnyObject) {
        drawColor = UIColor.blue
    }

    
    // 赤ボタン追加
    @IBAction func selectRed(_ sender: AnyObject) {
        drawColor = UIColor.red      //赤色に変更する
    }
    

    // 黒ボタン追加
    @IBAction func selectBlack(_ sender: AnyObject) {
        drawColor = UIColor.black
    }
    
    
    //
    @IBAction func pressSliderButton(_ sender: AnyObject) {
        myGreenSlider.isHidden = !myGreenSlider.isHidden
    }
    
  
}

