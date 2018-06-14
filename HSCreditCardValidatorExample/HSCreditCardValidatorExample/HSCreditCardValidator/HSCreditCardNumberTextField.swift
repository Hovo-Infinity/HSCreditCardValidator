//
//  HSCreditCardNumberTextField.swift
//  test
//
//  Created by Hovhannes Stepanyan on 6/12/18.
//  Copyright © 2018 Hovhannes Stepanyan. All rights reserved.
//

import UIKit

@objc
protocol HSCreditCardNumberTextFieldDelegate: NSObjectProtocol {
    @objc @available(iOS 2.0, *)
    optional func creditCardNumberTextFieldShouldBeginEditing(_ textField: HSCreditCardNumberTextField) -> Bool // return NO to disallow editing.
    
    @objc @available(iOS 2.0, *)
    optional func creditCardNumberTextFieldDidBeginEditing(_ textField: HSCreditCardNumberTextField) // became first responder
    
    @objc @available(iOS 2.0, *)
    optional func creditCardNumberTextFieldShouldEndEditing(_ textField: HSCreditCardNumberTextField, withValidCardNumber: Bool) -> Bool // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
    
    @objc @available(iOS 2.0, *)
    optional func creditCardNumberTextFieldDidEndEditing(_ textField: HSCreditCardNumberTextField, withValidCardNumber: Bool) // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
    
    @objc @available(iOS 10.0, *)
    optional func creditCardNumberTextFieldDidEndEditing(_ textField: HSCreditCardNumberTextField, reason: UITextFieldDidEndEditingReason) // if implemented, called in place of textFieldDidEndEditing:
    
    
    @objc @available(iOS 2.0, *)
    optional func creditCardNumberTextFieldShouldClear(_ textField: HSCreditCardNumberTextField) -> Bool // called when clear button pressed. return NO to ignore (no notifications)
}

@objc
class HSCreditCardNumberTextField: UITextField {
    /// Character that must be used for seporating numbers
    /// Default value is '-' so card number will be like this 1234-5678-9012-3456
    @IBInspectable var seporator: String = "-"
    private lazy var validator: HSCreditCardValidator = {
       HSCreditCardValidator(seporator: seporator)
    }()
    private var defaultTextColor: UIColor?
    override var delegate: UITextFieldDelegate? {
        didSet {
            if delegate?.isKind(of: HSCreditCardNumberTextField.self) == false {
                print("unable to set delegate, set cardNumberDelegate")
                delegate = self
            }
        }
    }
    
    /// Contains similar methods as UITextfieldDelegate, do not set delegate
    weak var cardNumberDelegate: HSCreditCardNumberTextFieldDelegate?
    /// Color indicates that card number is invalid
    @IBInspectable var invalidTextColor: UIColor = .red
    
    /// Color indicates that card number is valid
    @IBInspectable var validTextColor: UIColor = .green
    
    /// Allow to shake textfield if card number is invalid, default value is true
    @IBInspectable var shakeIfInvalid = true
    
    /// Return credit cary Type
    public private(set) var cardType: HSCreditCardValidator.CreditCardType?
    
    /// Return text without seporatorCaracter
    public var unformatedText: String? {
        get {
            return self.text?.replacingOccurrences(of: seporator, with: "")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        self.delegate = self
        self.defaultTextColor = self.textColor
        self.rightViewMode = .always
        self.keyboardType = .numberPad
        self.borderStyle = .line
        self.placeholder = "Card Number"
        addTarget(self, action: #selector(formatText), for: .editingChanged)
    }
    
    public func shake() {
        let shakeSize: CGFloat = 5.0
        let shakeDuration: CFTimeInterval = 0.1
        let shakeRepeatCount: Float = 2.0
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = shakeDuration
        animation.repeatCount = shakeRepeatCount
        animation.autoreverses = true
        animation.isRemovedOnCompletion = true
        animation.fromValue = CGPoint(x: self.center.x - shakeSize, y: self.center.y)
        animation.toValue = CGPoint(x: self.center.x + shakeSize, y: self.center.y)
        self.layer.add(animation, forKey: "shake")
    }
    
    // MARK: Action
    
    @objc private func formatText() {
        print("\(self.text ?? "no text")")
        for cardType in self.validator.allTypes {
            let format = HSCreditCardValidator.regExpFor(cardType)
            let predicate = NSPredicate(format: "SELF MATCHES %@", format)
            if predicate.evaluate(with: self.unformatedText) {
                self.cardType = cardType
                break
            } else {
                self.cardType = nil
            }
        }
        if cardType == nil || cardType == .Unknown {
            if shakeIfInvalid && (self.text?.count ?? 0) > 6 {
                self.shake()
            }
        } else {
            if self.validator.isValidCardNumber(self.unformatedText, for: self.cardType) {
                self.textColor = self.validTextColor
            } else {
                if (15...19) ~= (self.text?.count ?? 0) {
                    self.textColor = self.invalidTextColor
                    if shakeIfInvalid {
                        self.shake()
                    }
                } else {
                    self.textColor = self.defaultTextColor
                }
            }
        }
        self.rightView = UIImageView(image: HSCreditCardValidator.image(for: self.cardType ?? .Unknown))
        self.text = self.validator.cardNumberStyleString(from: self.unformatedText, type: self.cardType)
    }
}

extension HSCreditCardNumberTextField: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let count = (self.unformatedText?.count ?? 0) + string.count
        if let type = self.cardType {
            
            // TO-DO check by type
            switch type {
            case .AmericanExpress, .DinersClubInternational:
                if count > 15 {
                    return false || string.isEmpty
                } else {
                    return true
                }
            case .ChinaUnionPay:
                if count > 19 {
                    return false || string.isEmpty
                } else {
                    return true
                }
            case .DinersClubenRoute:
                if count > 14 {
                    return false || string.isEmpty
                } else {
                    return true
                }
            case .Maestro:
                if count > 19 {
                    return false || string.isEmpty
                } else {
                    return true
                }
            case .Visa,.VisaElectron,.MasterCard,.DinersClubUSAndCanada,.DiscoverCard,
                 .JBC,.Dankort,.BankCard,.MIR, .Arca:
                if count > 16 {
                    return false || string.isEmpty
                } else {
                    return true
                }
            default:
                if count > 7 {
                    return false || string.isEmpty
                } else {
                    return true
                }
            }
        }
        return false || string.isEmpty || count < 6
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if self.cardNumberDelegate?.responds(to: #selector(HSCreditCardNumberTextFieldDelegate.creditCardNumberTextFieldDidEndEditing(_:withValidCardNumber:))) == true {
            let isValid = self.validator.isValidCardNumber(self.unformatedText, for: self.cardType)
            self.cardNumberDelegate?.creditCardNumberTextFieldDidEndEditing!(self, withValidCardNumber: isValid)
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if self.cardNumberDelegate?.responds(to: #selector(HSCreditCardNumberTextFieldDelegate.creditCardNumberTextFieldShouldBeginEditing(_:))) == true {
            return (self.cardNumberDelegate?.creditCardNumberTextFieldShouldBeginEditing!(self))!
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if self.cardNumberDelegate?.responds(to: #selector(HSCreditCardNumberTextFieldDelegate.creditCardNumberTextFieldDidBeginEditing(_:))) == true {
            return (self.cardNumberDelegate?.creditCardNumberTextFieldDidBeginEditing!(self))!
        }
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if self.cardNumberDelegate?.responds(to: #selector(HSCreditCardNumberTextFieldDelegate.creditCardNumberTextFieldShouldEndEditing(_:withValidCardNumber:))) == true {
            let isValid = self.validator.isValidCardNumber(self.unformatedText, for: self.cardType)
            return (self.cardNumberDelegate?.creditCardNumberTextFieldShouldEndEditing!(self, withValidCardNumber: isValid))!
        }
        return true
    }
    
    @available(iOS 10.0, *)
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        if self.cardNumberDelegate?.responds(to: #selector(HSCreditCardNumberTextFieldDelegate.creditCardNumberTextFieldDidEndEditing(_:reason:))) == true {
            self.cardNumberDelegate?.creditCardNumberTextFieldDidEndEditing!(self, reason: reason)
        } else {
            self.textFieldDidEndEditing(textField)
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if self.cardNumberDelegate?.responds(to: #selector(HSCreditCardNumberTextFieldDelegate.creditCardNumberTextFieldShouldClear(_:))) == true {
            return (self.cardNumberDelegate?.creditCardNumberTextFieldShouldClear!(self))!
        }
        return true
    }
}

extension HSCreditCardValidator {
    static public func image(for type: CreditCardType) -> UIImage {
        switch type {
        case .AmericanExpress:
            return #imageLiteral(resourceName: "AmEx")
        case .BankCard:
            return #imageLiteral(resourceName: "bankcard")
        case .ChinaUnionPay:
            return #imageLiteral(resourceName: "chinaUnionPay")
        case .Dankort:
            return #imageLiteral(resourceName: "dankort")
        case .DinersClubenRoute,.DinersClubInternational, .DinersClubUSAndCanada:
            return #imageLiteral(resourceName: "dinersClub")
        case .JBC:
            return #imageLiteral(resourceName: "jbc")
        case .Maestro:
            return #imageLiteral(resourceName: "maestro")
        case .MIR:
            return #imageLiteral(resourceName: "mir")
        case .MasterCard:
            return #imageLiteral(resourceName: "masterCard")
        case .Visa:
            return #imageLiteral(resourceName: "visa")
        case .VisaElectron:
            return #imageLiteral(resourceName: "visaElectron")
        case .Arca:
            return #imageLiteral(resourceName: "ArCa")
        default:
            return #imageLiteral(resourceName: "unknown")
        }
    }
}
