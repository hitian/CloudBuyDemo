//
//  QRScanViewController.swift
//  YunBuy
//
//  Created by Jia Tian on 3/3/18.
//  Copyright © 2018 Jia Tian. All rights reserved.
//

import UIKit
import AVFoundation
import LocalAuthentication

class QRScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrcodeFrameView: UIView?
    var textLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        initUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initUI() {
        let captureDevice = AVCaptureDevice.default(for: .video)
        guard captureDevice != nil else {
            let alert = UIAlertController.init(title: "Notice", message: "No video device.", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            videoPreviewLayer?.connection?.videoOrientation = .portrait
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
            qrcodeFrameView = UIView()
            if let qrcodeFrameView = qrcodeFrameView {
                qrcodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrcodeFrameView.layer.borderWidth = 2
                view.addSubview(qrcodeFrameView)
                view.bringSubview(toFront: qrcodeFrameView)
            }
            
            textLabel = UILabel.init(frame: CGRect.init(
                x: (self.view.frame.width - 400) / 2,
                y: 150,
                width: 400,
                height: 20)
            )
            textLabel?.textColor = UIColor.white
            textLabel?.backgroundColor = UIColor.darkGray
            textLabel?.textAlignment = .center
            textLabel?.text = "没有检测到QRCode"
            view.addSubview(textLabel!)
            view.bringSubview(toFront: textLabel!)
        } catch {
            print(error)
            return
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let connection = self.videoPreviewLayer?.connection {
            connection.videoOrientation = getVideoOrientation()
        }
        print("view bounds viewWillTransition \(self.view.layer.bounds)")
        print("tosize: \(size)")
        videoPreviewLayer?.frame = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
        textLabel?.frame = CGRect.init(x: (size.width - 300) / 2, y: 150, width: 300, height: 20)
    }
    
    func getVideoOrientation() -> AVCaptureVideoOrientation{
        let currentDevice: UIDevice = UIDevice.current
        let orientation: UIDeviceOrientation = currentDevice.orientation
        switch (orientation)
        {
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrcodeFrameView?.frame = CGRect.zero
            setLabel(text: "没有检测到QRCode")
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrcodeFrameView?.frame = barCodeObject!.bounds
            if metadataObj.stringValue != nil {
                print("text: \(metadataObj.stringValue ?? "-")")
                checkOrderURL(str: metadataObj.stringValue!)
            }
        }
    }
    
    func setLabel(text: String) {
        textLabel?.text = text
    }
    
    func checkOrderURL(str: String) {
        
        if str.hasPrefix("http://ym.shop.ymwlw.com/v1/scan") {
            let url = URLComponents(string: str)
            var info: [String: String] = [:]
            for item in (url?.queryItems!)! {
                info[item.name] = item.value ?? ""
            }
            let orderInfo = OrderInfo.init(
                machNo: info["machNo"] ?? "",
                payType: info["payType"] ?? "",
                orderNo: info["orderNo"] ?? "",
                subject: (info["subject"] ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                goodsPrice: info["goodsPrice"] ?? "",
                goodsNo: info["goodsNo"] ?? "",
                merchantNo: info["merchantNo"] ?? ""
            )
            
            captureSession?.stopRunning()
            checkout(orderInfo)
            return
        }
        
        setLabel(text: "这个看起来不是自动售货机上的QRCode")
    }
    
    func checkout(_ orderInfo: OrderInfo) {
        let api = Api.instance()
        if api.isPayPasswordOk() {
            doPay(orderInfo)
            return
        }
        let authContext = LAContext()
        let myLocalizedReasonString = "Use LA to confirm the payment."
        var authError: NSError?
        if #available(iOS 8.0, *) {
            if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                authContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: myLocalizedReasonString, reply: { (isSuccess, error) in
                    if isSuccess {
                        api.loadPayPassword()
                        self.doPay(orderInfo)
                    } else {
                        print("auth failed")
                        self.showMessageAndDismiss("身份验证失败， 无法进行支付，请重试")
                    }
                })
            } else {
                let confirm = UIAlertController(title: "Confirm", message: "没有检测到 TouchID 或者 FaceID，要使用设备密码认证进行支付操作吗？", preferredStyle: .alert)
                confirm.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                    if authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
                        authContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: myLocalizedReasonString, reply: { (isSuccess, error) in
                            if isSuccess {
                                api.loadPayPassword()
                                self.doPay(orderInfo)
                            } else {
                                print("auth failed")
                                self.showMessageAndDismiss("设备密码错误， 无法进行支付，请重试")
                            }
                        })
                        
                    }
                }))
                confirm.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action) in
                    self.done()
                }))
                self.present(confirm, animated: true, completion: nil)
            }
        }
    }
    
    func doPay(_ orderInfo: OrderInfo) {
        print("do pay. \(orderInfo)")
        let api = Api.instance()
        textLabel?.text = "正在创建订单。。"
        api.doOrder(info: orderInfo) { (isSuccess, orderId, amount) in
            if !isSuccess {
                self.showMessageAndDismiss("创建订单失败: \(orderId)")
                return
            }
            self.textLabel?.text = "正在支付。。"
            api.doPay(orderId: orderId, completion: { (isSuccess, result) in
                if !isSuccess {
                    self.showMessageAndDismiss("创建支付失败: \(result)")
                    return
                }
                self.done()
            })
        }
    }
    
    func showMessageAndDismiss(_ message: String) {
        let alert = UIAlertController.init(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (action) in
            self.done()
        }))
        self.present(alert, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @objc func done() {
        if let session = captureSession {
            if session.isRunning {
                session.stopRunning()
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
}

