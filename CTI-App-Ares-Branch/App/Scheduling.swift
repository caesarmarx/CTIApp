//
//  Scheduling.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

/*************     NO SE USARA     ****************/

import Foundation
import UIKit
import CoreData

class Scheduling
{
    var timer = Timer()
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
    
    required init()
    {
        self.timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(Scheduling.updateTimeclocks), userInfo: nil, repeats: true)
    }
    
    //The timeclocks after end_time are sent to the server aumatically
    dynamic func updateTimeclocks()
    {
        let nowFormated = DateFormatter()
        //nowFormated.timeZone = NSTimeZone(abbreviation: "GMT")
        nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let date = nowFormated.string(from: Date())+" +0000"
        nowFormated.calendar = Calendar(identifier: .iso8601)
        nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss"
        nowFormated.locale = Locale(identifier: "en_US_POSIX")
        
        
        
        
        nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss xx"
        let date_set = nowFormated.date(from: date)
        
        let condition = NSPredicate(format: "end_time < %@", argumentArray: [date_set!])
        let getTc = NSFetchRequest<NSFetchRequestResult>(entityName: "Timeclock")
        getTc.predicate = condition
        
        do
        {
            let tc_searched = try self.managedObjectContext.fetch(getTc) as! [Timeclock]
            if tc_searched.count > 0
            {
                for tc in tc_searched
                {
                    /*nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss"
                    let end_tc = nowFormated.stringFromDate(tc.end_time!)
                    
                    nowFormated.timeZone = NSTimeZone(abbreviation: "GMT")
                    let end_final = nowFormated.dateFromString(end_tc)*/
                    
                    //Timeclock not started
                    if tc.status == 1
                    {
                        self.managedObjectContext.delete(tc)
                        try self.managedObjectContext.save()
                    }
                    // change status to 3
                    else if tc.status == 2
                    {
                        LocalNotification.sharedInstance.removeNotification(tc)
                        tc.status = 3
                        try self.managedObjectContext.save()
                    }
                    else if tc.status == 3
                    {
                        //Review the date
                        nowFormated.dateFormat = "YYYY-MM-dd HH:mm"
                        let right_now = nowFormated.string(from: Date()/*end_system!*/)
                        let end_system = nowFormated.date(from: right_now)
                        
                        let string_tc = nowFormated.string(from: tc.end_time! as Date)
                        let end_tc = nowFormated.date(from: string_tc)
                        
                        if end_tc!.compare(end_system!) == .orderedAscending
                        {
                            self.sent_tc_server(tc)
                        }
                    }
                    
                }
            }
        }
        catch
        {
            print("ERROR searching")
        }
    }
    
    func sent_tc_server(_ tc:Timeclock)
    {
        //Send data to server
        let settings = UserDefaults.standard
        //Data access
        let token = settings.string(forKey: "session")
        let user = settings.string(forKey: "user")
        
        //Create request
        let request = NSMutableURLRequest(url: URL(string: "https://globo.ctitranslators.com/index.php/api/timeclock_app/updateTimeclock")!)
        //Create data to send to timeclock
        let nowFormated = DateFormatter()
        nowFormated.dateFormat = "HH:mm"
        
        let start = nowFormated.string(from: tc.start_time! as Date)
        //nowFormated.timeZone = NSTimeZone(abbreviation: "GMT")
        let end = nowFormated.string(from: tc.end_time! as Date)
        let job = tc.job?.stringValue
        let id = tc.id?.stringValue
        var data = "session="+token!+"&user="+user!+"&start="+start
        data += "&end="+end+"&job="+job!+"&id="+id!
        //Define method Post
        request.httpMethod = "POST"
        //Send data to request
        request.httpBody = data.data(using: String.Encoding.utf8)
        
        //Start conection whit server
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
                //Error in session
                data,response, error in guard error == nil && data != nil else
                {
                    print("error=\(error)")
                    return
                }
                //The server responsed whit a bad status
                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200
                {
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(response)")
                    return
                }
                //dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                    //We have a good response from the server
                    do
                    {
                        //Read response as json
                        let response = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String:Any]
                        
                        //The status of request
                        let status = Int(response["status"] as! NSNumber)
                        print("response server \(response)")
                        //Timeclock updated
                        if status == 1
                        {
                            self.managedObjectContext.delete(tc)
                            try self.managedObjectContext.save()
                        }
                    }
                    catch
                    {
                        print("error JSON: \(error)")
                    }
                //})
        })            

        task.resume()
    }
}
