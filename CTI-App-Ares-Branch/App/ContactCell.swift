//
//  ContactCell.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation
import UIKit
class ContactCell: UITableViewCell
{
    
    
    @IBOutlet weak var Name_Contact: UILabel!
    //Job of cell
    var contact:Contact = Contact()
    
    //Load data of the job
    func load()
    {
        self.Name_Contact.text = self.contact.name
    }
}
