//
//  ViewController.swift
//  YunBuy
//
//  Created by Jia Tian on 3/2/18.
//  Copyright © 2018 Jia Tian. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkAccount()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkAccount() {
        let username = Account().readUsername()
        if username == nil {
            //show account set view.
            self.performSegue(withIdentifier: "show_account", sender: nil)
        }
    }

}

