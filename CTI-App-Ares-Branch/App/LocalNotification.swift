//
//  LocalNotification.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//
import Foundation
import UIKit

class LocalNotification
{
    class var sharedInstance:LocalNotification
    {
        struct Static {
            static let instance: LocalNotification = LocalNotification()
        }
        return Static.instance
    }
    
    // Create notification to ask more time
    // option:  0 -> 10 mins before end time
    //          1 -> 5 mins before end time
    func addNotification(_ tc:Timeclock, option:Int)
    {        
        let local_not = UILocalNotification()
        local_not.alertBody = (option == 0 ? "Do you need more time for the request \(tc.job!)?" : "Your request is nearly over, please call this number if you need an extension")
        local_not.alertAction = "Ask time"
        local_not.soundName = UILocalNotificationDefaultSoundName
        
        //Date to fire notification
//        let nowFormated = DateFormatter()
        
//        nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss"
//        let right_now = nowFormated.string(from: Date())+" +0000"
//        nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss xx"
        //nowFormated.timeZone = NSTimeZone(abbreviation: "GMT")
        
//        let system_date = nowFormated.date(from: right_now)
        
        if tc.end_time != nil {
            local_not.fireDate = tc.end_time!.addingTimeInterval(option==0 ? -600 : -300)
            local_not.userInfo = ["tc":tc.id!]
            local_not.category = "Timeclock"
            
            let settings = UserDefaults.standard
            let count = settings.string(forKey: "alerts")
            
            var counter = (count == nil ? 0 : Int(count! as String))
            
            if(counter != nil || counter! != 0)
            {
              counter? += 1
            }
            else
            {
              counter = 1
            }
            
            settings.set(counter, forKey:"alerts")
            settings.synchronize()
            
            //settings.setObject(self.mail.text, forKey:"user")
            
            UIApplication.shared.scheduleLocalNotification(local_not)
        }
      
    }
    
    //Delete notification when user doesn't want more time
    func removeNotification(_ tc: Timeclock)
    {
        if UIApplication.shared.scheduledLocalNotifications == nil {
            return
        }
        
        for notification in UIApplication.shared.scheduledLocalNotifications!
        {
            let notificationId = notification.userInfo?["tc"] as! NSNumber
            
            if notificationId == tc.id
            {
                UIApplication.shared.cancelLocalNotification(notification)
                let settings = UserDefaults.standard
                var counter = Int(settings.string(forKey: "alerts")! as String)
                
                if(counter != nil || counter! != 0)
                {
                    counter? -= 1
                }
                else
                {
                    counter = 0
                }
                
                settings.set(counter, forKey:"alerts")
                settings.synchronize()
            }
        }
    }
}
