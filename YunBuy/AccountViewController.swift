//
//  AccountViewController.swift
//  YunBuy
//
//  Created by Jia Tian on 3/3/18.
//  Copyright © 2018 Jia Tian. All rights reserved.
//

import UIKit

class AccountViewController: UITableViewController {
    let accountManager = Account()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        let username = accountManager.readUsername() ?? ""
        phoneTextField.text = username
        
//        let loginPassword = accountManager.readPassword()
//        let payPassword = accountManager.readLoginPassword()
        
    }
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var payPasswordTextField: UITextField!
    @IBAction func save(_ sender: UIButton) {
        let username = phoneTextField.text ?? ""
        guard username != "" else {
            showAlert(text: "Phone number can not be empty!")
            return
        }
        
        let loginPassword = passwordTextField.text ?? ""
        guard loginPassword != "" else {
            showAlert(text: "Login password can not be empty!")
            return
        }
        
        let payPassword = payPasswordTextField.text ?? ""
        guard payPassword != "" else {
            showAlert(text: "Pay password can not be empty!")
            return
        }
        
        accountManager.setUsername(username: username)
        accountManager.setPassword(password: loginPassword)
        accountManager.setPayPassword(password: payPassword)
        
        //delete token after account info changed.
        accountManager.setToken(token: "")
        
        let alert = UIAlertController.init(title: "Notice", message: "Saved", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlert(text: String) {
        let alert = UIAlertController.init(title: "Error", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func done() {
        self.dismiss(animated: true, completion: nil)
    }
    
}
