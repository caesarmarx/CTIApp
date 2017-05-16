//
//  ResponseViewController.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class ResponseViewController: UIViewController
{
    var time: NSNumber = 0 //Time in seconds
    var job: NSNumber = 0
    
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
    
    @IBOutlet weak var lblResponse: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if self.time == 0
        {
            self.lblTime.isHidden = true
            self.lblResponse.text = "The time was rejected"
        }
        else
        {
            self.lblResponse.text = "You have more time"
            self.lblTime.text = self.seconds_to_string()
        }
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(ResponseViewController.close))
    }
    
    func close() {
        dismiss(animated: true, completion: nil)
    }
    
    func seconds_to_string() -> String
    {
        var minutes = Int(self.time.intValue/60)
        let hour = Int(minutes/60)
        self.create_tc(minutes)
        minutes = minutes - (hour * 60)
        return String(hour) + ":" + String(minutes)
    }
    
    func create_tc(_ minutes: Int)
    {
        
        //Update timeclock if exists in local DB
        let condition = NSPredicate(format: " %K == %D", "job", Int(self.job))
        print(condition)
        let getTc = NSFetchRequest<NSFetchRequestResult>(entityName: "Timeclock")
        getTc.predicate = condition
        getTc.fetchLimit = 1
        
        var timer:Timeclock?
        
        do
        {
            let tc_searched = try self.managedObjectContext.fetch(getTc) as! [Timeclock]
            if tc_searched.count > 0
            {
                //print(tc_searched.first)
                timer = tc_searched.first! //as Timeclock
                print(timer!)
                timer!.end_time = timer?.end_time?.addingTimeInterval(Double(minutes)*60)
                print(timer!)
                
                do
                {
                    try managedObjectContext.save()
                }
                catch
                {
                    print("ERROR WHEN UPDATE END TIME")
                }
            }
        }
        catch
        {
            print("ERROR searching")
        }
    }
}
