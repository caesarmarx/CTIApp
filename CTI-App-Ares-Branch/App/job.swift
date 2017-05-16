//
//  job.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation

//Model of request

class Job
{
    var number:Int = 0
    var company:String = ""
    var branch:String = ""
    var start_time:String = ""
    var end_time:String = ""
    var date:String = ""
    
    init()
    {
        
    }
    init(data:NSDictionary)
    {
        self.number = Int(data["job"] as! String)!
        self.company = data["empresa"] as! String
        self.branch  = data["sucursal"] as! String
        self.start_time = data["start_time"] as! String
        self.end_time = data["end_time"] as! String
        self.date = data["date"] as! String
    }
    
    func accept_reject(_ response:Bool)->Bool
    {
        return true
    }
}
