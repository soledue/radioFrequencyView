//
//  ViewController.swift
//  RadioFrequencyView
//
//  Created by Ivailo Kanev on 26/09/22.
//

import UIKit
import RadioFrequencyView

class ViewController: UIViewController {
    @IBOutlet var radioView: RadioFrequencyView!
    
    @IBAction func amPressed(_ sender: Any) {
        radioView.preset = .am
    }
    @IBAction func fmPressed(_ sender: Any) {
        radioView.preset = .fm
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        radioView.getFrequency 
    }


}

