//
//  Contact.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation

//Model of Contact

class Contact
{
    var id:NSNumber = 0
    var name:String = ""
    var type:String = ""
    
    init()
    {
        
    }
    init(data:NSDictionary, entity:String)
    {
        self.id = data["id"] as! NSNumber
        self.name = data["nombre"] as! String
        self.type = entity
    }
    init(number: Int, nameContact: String, entity:String)
    {
        self.id = number as NSNumber
        self.name = nameContact
        self.type = entity
    }
}
