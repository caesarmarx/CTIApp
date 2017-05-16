//
//  TimeclockCell.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation
import UIKit

class TimeclockCell: UITableViewCell
{
    //Object timeclock
    var tc:Timeclock?
    @IBOutlet weak var tc_job: UILabel!
    @IBOutlet weak var tc_client: UILabel!
    //Show info of timeclock in the cell
    func load()
    {
        self.tc_job.text = self.tc?.job?.stringValue
        self.tc_client.text = self.tc?.branch
    }
}
