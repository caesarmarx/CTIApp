//
//  AlertViewController.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation
import UIKit

class AlertController
{
    
    //function to create alert whit an especified action
    func alertError(_ title_alert: String, msg: String, opt: String)-> UIAlertController
    {
        let alert = UIAlertController(title: title_alert, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: opt, style: UIAlertActionStyle.default, handler: nil))
        
        return alert
    }
    
    //function to create alert whitout Options
    func alertConfirm(_ title_alert: String, msg: String)-> UIAlertController
    {
        let alert = UIAlertController(title: title_alert, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        
        return alert
    }
}
