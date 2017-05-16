//
//  TimeclockController.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//
import Foundation
import UIKit
import CoreData
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

class TimeclockController: UITableViewController
{
    var tcs: [Timeclock] = []
    var tcs_filtered: [Timeclock] = []
    var filter_value: [Float] = [-Float.greatestFiniteMagnitude , 24, 24 * 7, 24 * 7 * 2, 24 * 30, 24 * 30 * 3]
    var string_value: [String] = ["Today", "Current Week", "Current 2 Weeks", "Current Month", "Current Quarter"]
    var filter_index = 0
    
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
    
    override func viewDidAppear(_ animated: Bool) {
        //To update new timeclocks and start/end time of them
        if Reachability.isConnectedToNetwork()
        {
            self.get_timeclocks()
        }
        else
        {
            let alert = AlertController().alertError("Network error",msg: "Please verify your network connection",opt: "Accept")
            self.present(alert, animated: true, completion: nil)
            self.read_timeclock_local()
        }
        NSLog("viewdidappear")
        self.tableView.reloadData()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        let buttonFilter = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        buttonFilter.setImage(UIImage(named: "filter.png"), for: .normal)
        buttonFilter.addTarget(self, action: #selector(self.select_filter(_:)), for: .touchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttonFilter)
    }
    
    func get_filtered(_ index: Int) {
        tcs_filtered = tcs.filter({
            //return $0.id != -1
            let date = Date()
            let units: Set<Calendar.Component> = [.day, .month, .year]
            let calendar = Calendar.current
            let comps = calendar.dateComponents(units, from: date)
            let newDate = calendar.date(from: comps)
            
            var value = $0.fecha?.timeIntervalSince(newDate!)
            if value == nil {
                value = 0
            }
            return Float(value!) / 60 / 60 >= filter_value[0] && Float(value!) / 60 / 60 < filter_value[index + 1]
        })
        //navigationItem.rightBarButtonItem?.title = string_value[index]
        tableView.reloadData()
    }
    
    func select_filter(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: string_value[0], style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
            self.filter_index = 0
            self.get_filtered(self.filter_index)
        }))
        alertController.addAction(UIAlertAction(title: string_value[1], style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
            self.filter_index = 1
            self.get_filtered(self.filter_index)
        }))
        alertController.addAction(UIAlertAction(title: string_value[2], style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
            self.filter_index = 2
            self.get_filtered(self.filter_index)
        }))
        alertController.addAction(UIAlertAction(title: string_value[3], style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
            self.filter_index = 3
            self.get_filtered(self.filter_index)
        }))
        alertController.addAction(UIAlertAction(title: string_value[4], style: UIAlertActionStyle.default, handler: { (action: UIAlertAction!) in
            self.filter_index = 4
            self.get_filtered(self.filter_index)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func get_timeclocks()
    {
        //Create request
        let request = NSMutableURLRequest(url: URL(string: "https://globo.ctitranslators.com/index.php/api/timeclock_app/get_timeclocks")!)
        
        //Create data to send to request, the token given and the username
        let settings = UserDefaults.standard
        //Data access
        let token = settings.string(forKey: "session")
        let user = settings.string(forKey: "user")
        let data = "user=" + user! + "&session=" + token!
        //Define method Post
        request.httpMethod = "POST"
        //Send data to request
        request.httpBody = data.data(using: String.Encoding.utf8)
        
        NSLog("Sent request for get_timeclocks")
        
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
            }
            
            NSLog("Received response for get_timeclocks")
            
            DispatchQueue.main.async(execute: { () -> Void in
                //We have a good response from the server
                do
                {
                    //Read response as json
                    let response = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String:Any]
                    print(response)
                    //The status of login
                    let status = Int(response["status"] as! NSNumber)
                    
                    //NO TOKEN INTO DB
                    if status < 0
                    {
                        settings.removeObject(forKey: "user")
                        settings.removeObject(forKey: "password")
                        settings.removeObject(forKey: "session")
                        settings.removeObject(forKey: "profile")
                        settings.removeObject(forKey: "interprete")
                        settings.removeObject(forKey: "qr")
                        settings.synchronize()
                      
                        //Go to next screen
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "login")
                        self.present(vc, animated: true, completion: nil)
                        TimeclockController.deleteTimeclocks()
                    }
                        //print("first action \(response)")
                    else if status > 0
                    {
                        //Delete all timeclocks with status 1 and their notificactions
//                        self.deleteTimeclocks()
                        //print(response)
                        let timeclocks = response["timeclocks"]! as! [[String: AnyObject]]
                        
                        //fill jobs
                        for timeclock in timeclocks
                        {
                            self.create_tc(timeclock as NSDictionary)
                        }
                        
                        // Remove deleted timeclocks
                        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Timeclock")
                        let existingTimeClocks = try self.managedObjectContext.fetch(fetch) as! [Timeclock]
                        for timeclock in existingTimeClocks {
                            if (timeclocks.filter({ (timeclockDic) -> Bool in
                                let aId = Int(timeclockDic["id"]! as! String)
                                return aId == timeclock.id!.intValue
                            }).count == 0) {
                                LocalNotification.sharedInstance.removeNotification(timeclock)
                                self.managedObjectContext.delete(timeclock)
                            }
                        }
                        
                        NSLog("Updated time clocks")
                        self.read_timeclock_local()
                    }
                    //
                    else  {
                        self.read_timeclock_local()
                    }
                }
                catch
                {
                    print("error JSON: \(error)")
                }
            })
        })        

        task.resume()
    }
    
    func combineDateTime(fecha: Date, times: Date) -> Date {
        let funits: Set<Calendar.Component> = [.day, .month, .year]
        let tunits: Set<Calendar.Component> = [.hour, .minute, .second]
        let calendar = Calendar.current
        var fcomps = calendar.dateComponents(funits, from: fecha)
        let tcomps = calendar.dateComponents(tunits, from: times)
        fcomps.hour = tcomps.hour
        fcomps.minute = tcomps.minute
        fcomps.second = tcomps.second
        let newDate = calendar.date(from: fcomps)
        return newDate!
    }
    
    func create_tc(_ data: NSDictionary)
    {
        //save data
        let nowFormated = DateFormatter()
        nowFormated.dateFormat = "YYYY-MM-dd"
        print(data)
        let today = nowFormated.string(from: Date())
        
        let start = today+" "+(data["start_time"]!  as! String)
        let end = (data["end_time"] != nil && data["end_time"] as? String != nil) ? (today+" "+(data["end_time"]!  as! String)) : ""

        nowFormated.calendar = Calendar(identifier: .iso8601)
        nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss"
        nowFormated.locale = Locale(identifier: "en_US_POSIX")
        
        //Update timeclock if exists in local DB
        let condition = NSPredicate(format: "id == %@", argumentArray: [Int(data["id"]! as! String)!])
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
                timer = tc_searched.first!
                if(timer?.status == 1)
                {
                    timer!.start_time = combineDateTime(fecha: timer!.fecha!, times: nowFormated.date(from: start)!)
                }
                if(timer?.status != 3)
                {
                    let newTime = combineDateTime(fecha: timer!.fecha!, times: nowFormated.date(from: end)!)
                    if timer!.end_time != newTime {
                        timer!.end_time = newTime
                        LocalNotification.sharedInstance.removeNotification(timer!)
                        LocalNotification.sharedInstance.addNotification(timer!,option: 0)
                        LocalNotification.sharedInstance.addNotification(timer!,option: 1)
                    }
                }
                do
                {
                    try self.managedObjectContext.save()
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

        //Create timeclock
        if(timer == nil)
        {
            let timeclock = NSEntityDescription.insertNewObject(forEntityName: "Timeclock", into: self.managedObjectContext) as! Timeclock
            
            timeclock.id = Int(data["id"]! as! String) as NSNumber?
            timeclock.job = Int(data["id_solicitud"]! as! String) as NSNumber?
            timeclock.branch = data["sucursal"]! as? String
            timeclock.company = data["empresa"]! as? String
            timeclock.end_code = data["end_code"]! as? String
            timeclock.start_code = data["start_code"]! as? String

            timeclock.status = Int(data["status"]! as! String) as NSNumber?
            timeclock.telephone = (data["telefono"] != nil ? data["telefono"]! as? String : "")
            timeclock.ipad = (data["ipad"] != nil && data["ipad"] as? String != nil) ? Int(data["ipad"] as! String) as NSNumber? : 0
            
            let formatted = DateFormatter()
            formatted.dateFormat = "yyyy-MM-dd"
            timeclock.fecha = formatted.date(from: data["fecha"] as! String)
            
            timeclock.start_time = combineDateTime(fecha: timeclock.fecha!, times: nowFormated.date(from: start)!)
            timeclock.end_time = combineDateTime(fecha: timeclock.fecha!, times: nowFormated.date(from: end)!)
            
            print(formatted.string(from: Date()))
            do
            {
                try managedObjectContext.save()
                //self.tcs.append(timeclock)
                
                let settings = UserDefaults.standard
                let count = settings.string(forKey: "alerts")
                
                let counter = (count == nil ? 0 : Int(count! as String))
                
                
                //Create alert to timeclocks without ipad timeclock.ipad == 1 &&
                if(counter == nil || counter < 64)
                {
                    LocalNotification.sharedInstance.addNotification(timeclock,option: 0)
                    LocalNotification.sharedInstance.addNotification(timeclock,option: 1)
                    //self.performSegueWithIdentifier("return_timeclocks", sender: self)
                    //counter = counter! + 1
                    //settings.setObject(counter, forKey:"alerts")
                    //settings.synchronize()
                }
            }
            catch
            {
                print("ERROR DATOS")
            }
            
        }
    }
    
    func read_timeclock_local()
    {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Timeclock")
        do
        {
            NSLog("Fetched data from core data")
            self.tcs = try self.managedObjectContext.fetch(fetch) as! [Timeclock]
            
            self.tcs.sort(by: { (time1, time2) -> Bool in
                
                return time1.job!.intValue < time2.job!.intValue
            })
            
            DispatchQueue.main.async {
                NSLog("Reloaded table view")
                self.get_filtered(self.filter_index)
                self.tableView.reloadData()
            }
        }
        catch let error as NSError
        {
            print(error)
        }
    }
    
    static func deleteTimeclocks()
    {
        //Delete timeclocks with status = 1
        let deleteCond = NSPredicate(format: "status == %@", argumentArray: [1])
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Timeclock")
        fetch.predicate = deleteCond
        
        //let instruction = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do
        {
            let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
            let tcDelete = try managedObjectContext.fetch(fetch) as! [Timeclock]
            for tc in tcDelete
            {
                //Delete local notification
                LocalNotification.sharedInstance.removeNotification(tc)
                managedObjectContext.delete(tc)
            }
            try managedObjectContext.save()
        }
        catch let error as NSError
        {
            print(error)
        }
        //Delete all local notifications
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tcs_filtered.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tc_cell", for: indexPath) as! TimeclockCell
        if indexPath.row < self.tcs_filtered.count
        {
            cell.tc = self.tcs_filtered[indexPath.row]
            cell.load()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "detail_tc"
        {
            let cell = sender as? UITableViewCell
            let index = tableView.indexPath(for: cell!)
            
            let detail = segue.destination as! DetailTimeclockController
            detail.tc = self.tcs_filtered[(index?.row)!]
        }
    }
}
