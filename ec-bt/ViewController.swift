//
//  ViewController.swift
//  ec-bt
//
//  Created by Kumari, Reena on 8/30/18.
//  Copyright © 2018 Kumari, Reena. All rights reserved.
//

import UIKit
import Braintree
import Braintree.BraintreePayPal

class ViewController: UIViewController, BTAppSwitchDelegate, BTViewControllerPresentingDelegate  {
    
    var braintreeClient: BTAPIClient?
    var client_token: String!
    override func viewDidLoad() {
        super.viewDidLoad()
        getClientToken();
    }
    
    func getClientToken(){
        guard let url = URL(string: "https://bt-direct.herokuapp.com/payments/client_token") else {return}
        let session = URLSession.shared;
        session.dataTask(with: url) { (data, response, error) in
            if let data = data {
                self.client_token = String(data: data, encoding: String.Encoding.utf8);
                print(self.client_token);
            }
            }.resume();
    }
    
    @IBAction func pay(_ sender: UIButton) {
        
        braintreeClient = BTAPIClient(authorization: client_token)
        
        let payPalDriver = BTPayPalDriver(apiClient: braintreeClient!)
        payPalDriver.viewControllerPresentingDelegate = self
        payPalDriver.appSwitchDelegate = self // Optional
        
        let request = BTPayPalRequest(amount: "2.32")
        request.currencyCode = "INR"
        
        payPalDriver.requestOneTimePayment(request) { (tokenizedPayPalAccount, error) in
            if let tokenizedPayPalAccount = tokenizedPayPalAccount {
                print("Got a nonce: \(tokenizedPayPalAccount.nonce)")
                
                let payload = ["amount": "2.32", "nonce": tokenizedPayPalAccount.nonce];
                guard let body = try? JSONSerialization.data(withJSONObject: payload, options: []) else {return}
                
                guard let url = URL(string: "https://bt-direct.herokuapp.com/payments/checkout") else {return}
                
                var urlRequest = URLRequest(url: url);
                urlRequest.httpMethod = "POST";
                urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = body;
                
                let session = URLSession.shared;
                session.dataTask(with: urlRequest) { (data, response, error) in
                    if let data = data {
                        do{
                            let jsonData = try JSONSerialization.jsonObject(with: data, options: [])
                            print(jsonData);
                        }catch {
                            print("error");
                        }
                    }
                    }.resume();
                
            } else if let error = error {
                print(error);
            } else {
                // Buyer canceled payment approval
            }
        }
    }
    
    func paymentDriver(_ driver: Any, requestsPresentationOf viewController: UIViewController) {
        present(viewController, animated: true, completion: nil)
    }
    
    func paymentDriver(_ driver: Any, requestsDismissalOf viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }

    func appSwitcherWillPerformAppSwitch(_ appSwitcher: Any) {
        showLoadingUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(hideLoadingUI), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func appSwitcherWillProcessPaymentInfo(_ appSwitcher: Any) {
        hideLoadingUI()
    }
    
    func appSwitcher(_ appSwitcher: Any, didPerformSwitchTo target: BTAppSwitchTarget) {
        
    }
    
    // MARK: - Private methods
    
    func showLoadingUI() {
        // ...
    }
    
    func hideLoadingUI() {
        NotificationCenter
            .default
            .removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        // ...
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

