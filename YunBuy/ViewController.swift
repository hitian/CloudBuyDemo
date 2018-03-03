//
//  ViewController.swift
//  YunBuy
//
//  Created by Jia Tian on 3/2/18.
//  Copyright © 2018 Jia Tian. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    
    let api = Api()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("viewDidLoad")
        balanceLabel.text = "Loading.."
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
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
            let alert = UIAlertController.init(title: "Notice", message: "You need set the account info first.", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (action) in
                self.showAccount()
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            usernameLabel.text = username
            api.balance(completion: { (isOk, data) in
                DispatchQueue.main.async {
                    if isOk {
                        self.balanceLabel.text = "\(data)"
                    } else {
                        print("ERROR: \(data)")
                        self.balanceLabel.text = "err"
                    }
                }
            })
        }
    }
    
    func showAccount() {
        self.performSegue(withIdentifier: "show_edit_account", sender: nil)
    }
    @IBOutlet weak var testLabel: UILabel!
    
}

