//
//  ViewController.swift
//  HSCreditCardValidatorExample
//
//  Created by Hovhannes Stepanyan on 6/14/18.
//  Copyright © 2018 Hovhannes Stepanyan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet private weak var textField: HSCreditCardNumberTextField!
    @IBOutlet private weak var infoLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.cardNumberDelegate = self
        textField.shakeIfInvalid = false
    }
    
    @IBAction func validate() {
        textField.resignFirstResponder()
    }
}

extension ViewController: HSCreditCardNumberTextFieldDelegate {
    func creditCardNumberTextFieldDidEndEditing(_ textField: HSCreditCardNumberTextField, withValidCardNumber: Bool) {
        if withValidCardNumber {
            infoLabel.text = "Card number is VALID"
        } else {
            infoLabel.text = "Card number INVALID"
        }
    }
}
