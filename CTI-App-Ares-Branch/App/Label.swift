//
//  Label.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation
import UIKit

class Label: UILabel
{
    override func drawText(in rect: CGRect)
    {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)))
    }
}
