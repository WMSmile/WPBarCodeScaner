//
//  WPBarCodeScannerViewController.swift
//  WPBarCodeScannerDemo
//
//  Created by wumeng on 2022/3/1.
//

import UIKit
import WPBarCodeScanner

class WPBarCodeScannerViewController: UIViewController {
    
    private var cameraView:UIView!
    private var barCodeScanner:WPBarCodeScanner.WPBarcodeScanner!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.WM_FUNC_initViews()
        self.WM_FUNC_initScanner()
    }
    
    
    //init
    func WM_FUNC_initViews() -> Void {
        
        self.cameraView = UIView.init(frame: self.view.frame)
        self.view.addSubview(self.cameraView)
        
        
        
        let disBtn = UIButton.init(frame: CGRect.init(x: 20, y: 20, width: 100, height: 60))
        disBtn.backgroundColor = UIColor.black
        disBtn.setTitle("返回", for: UIControl.State.normal)
        disBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        self.view.addSubview(disBtn)
        
        disBtn.addTarget(self, action: #selector(WM_FUNC_dismissClick(sender:)), for: UIControl.Event.touchUpInside)
        
        
        
    }
    
    //
    func WM_FUNC_initScanner() -> Void {
        self.barCodeScanner = WPBarCodeScanner.WPBarcodeScanner.init(self.cameraView);
        
        
    }

    
    
    
    
    

    @objc func WM_FUNC_dismissClick(sender:Any) -> Void {
         self.dismiss(animated: true) {
             
         }
     }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        WPBarcodeScanner.requestCameraPermission({ success in
            if success {
                self.barCodeScanner.startScanning(WPCamera.back) { results in
                    print("result >>>> \(String(describing: results))")
                    if results?.count ?? 0 >= 1 {
                        for item in results ?? [] {
                            print("barcode == \(item.payloadStringValue ?? "")")
                        }
                        self.dismiss(animated: true) {
                            print("dismiss")
                        }
                    }
                }
            }else{
                print("未获取相机权限 >>>>>")
            }
        })
        
        
        
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.barCodeScanner.stopScaning();
    }
    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
