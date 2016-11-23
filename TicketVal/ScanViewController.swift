//
//  MainViewController.swift
//  TicketVal
//
//  Created by Alex on 20.06.16.
//  Copyright © 2016 Alex. All rights reserved.
//

import UIKit
import AVFoundation


class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBAction func light(_ sender: Any) {
        toggleFlash()
    }
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    // Added to support different barcodes
    let supportedBarCodes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeUPCECode, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeAztecCode]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
        // as the media type parameter.
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // Detect all the supported bar code
            captureMetadataOutput.metadataObjectTypes = supportedBarCodes
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture
            captureSession?.startRunning()
            
            // Move the message label to the top view
            view.bringSubview(toFront: messageLabel)
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront: qrCodeFrameView)
            }
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.backgroundColor = UIColor.lightGray
            messageLabel.text = "Es wurde kein QR-Code erkannt!"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        var valid:Bool = false
        
        //let editViewController: EditViewController = EditViewController(nibName: nil, bundle: nil)
        
        
        // Here we use filter method to check if the type of metadataObj is supported
        // Instead of hardcoding the AVMetadataObjectTypeQRCode, we check if the type
        // can be found in the array of supported bar codes.
        if supportedBarCodes.contains(metadataObj.type) {
            //        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                
                
                valid = DBViewController().validate(metadataObj.stringValue)
                
                if (valid == true){
                    messageLabel.backgroundColor = UIColor.green
                    messageLabel.text = "Ticket gültig!"
                    /*
                    let alert_valid = UIAlertController(title: "Ticket gültig!", message: "\(metadataObj.stringValue)", preferredStyle: UIAlertControllerStyle.alert)
                    let backView = alert_valid.view.subviews.last?.subviews.last
                    backView?.layer.cornerRadius = 10.0
                    backView?.backgroundColor = UIColor.green
                    alert_valid.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert_valid, animated: true, completion: nil)
                    */
                    
                
                    
                }else{
                    messageLabel.backgroundColor = UIColor.red
                    messageLabel.text = "Ticket ungültig!"
                    
                    /*
                    let alert_invalid = UIAlertController(title: "Ticket ungültig!", message: "\(metadataObj.stringValue)", preferredStyle: UIAlertControllerStyle.alert)
                    let backView = alert_invalid.view.subviews.last?.subviews.last
                    backView?.layer.cornerRadius = 10.0
                    backView?.backgroundColor = UIColor.red
                    alert_invalid.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert_invalid, animated: true, completion: nil)
                    */
                    }
 
                }
            }
        }
    
    func toggleFlash() {
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        if (device?.hasTorch)! {
            do {
                try device?.lockForConfiguration()
                if (device?.torchMode == AVCaptureTorchMode.on) {
                    device?.torchMode = AVCaptureTorchMode.off
                } else {
                    do {
                        try device?.setTorchModeOnWithLevel(1.0)
                    } catch {
                        print(error)
                    }
                }
                device?.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
}
