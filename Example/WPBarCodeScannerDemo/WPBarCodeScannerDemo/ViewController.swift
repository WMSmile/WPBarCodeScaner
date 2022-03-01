//
//  ViewController.swift
//  WPBarCodeScannerDemo
//
//  Created by wumeng on 2022/3/1.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func goToScanner(_ sender: Any) {
        
        let barCodeScannerVC = WPBarCodeScannerViewController()
        self.present(barCodeScannerVC, animated: true) {
            print("finish >>>.")
        }
        
    }
}

