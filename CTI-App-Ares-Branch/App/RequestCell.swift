//
//  RequestCell.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation
import UIKit
class RequestCell: UITableViewCell
{
    
    @IBOutlet weak var number_job: UILabel!
    @IBOutlet weak var job_sucursal: UILabel!
    //Job of cell
    var request:Job = Job()
    
    //Load data of the job
    func load()
    {
        self.number_job.text = String(self.request.number)
        self.job_sucursal.text = self.request.branch /*self.request.company+", "+*/
    }
}
