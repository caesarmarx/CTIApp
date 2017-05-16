//
//  RequestViewController.swift
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


class RequestViewController: UIViewController
{
    var request: Job = Job()
    var response: Int = 2 //Not internet
    var status: Int = 0   //0 = new, 1 = edited
    
    //Components
    @IBOutlet weak var job_number: UILabel!
    @IBOutlet weak var job_date: UILabel!
    @IBOutlet weak var job_company: UILabel!
    @IBOutlet weak var job_branch: UILabel!
    @IBOutlet weak var start: UILabel!
    @IBOutlet weak var end: UILabel!
    @IBOutlet weak var btn_accept: UIButton!
    @IBOutlet weak var btn_reject: UIButton!
    
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext

    override func viewWillAppear(_ animated: Bool)
    {
        if(Reachability.isConnectedToNetwork())
        {
            self.validate_job()
        }
        else //Not internet
        {
            let alert = AlertController().alertError("Network error",msg: "Please verify your network connection",opt: "Accept")
            self.present(alert, animated: true, completion: nil)
        }
    }
    override func viewDidLoad()
    {
        super.viewDidAppear(true)
    }
    
    //Accept the request
    @IBAction func accept_job(_ sender: UIButton)
    {
        if(Reachability.isConnectedToNetwork())
        {
            self.response = 1
            self.send_response()
        }
    }
    
    //Reject the request
    @IBAction func reject_job(_ sender: UIButton)
    {
        //Confirm the choice
        let confirm = AlertController().alertConfirm("Confirmation",msg: "Are you sure you want to reject the request?")
        
        //If yes then send response
        confirm.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
            if(Reachability.isConnectedToNetwork())
            {
                self.send_response()
            }
        }))
        //Close Request
        confirm.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
        self.present(confirm, animated: true, completion: nil)
    }
    
    //Validate that can accept/reject the request
    func validate_job()
    {
        let url = "https://globo.ctitranslators.com/index.php/api/request_app/validate_job"
        let info = "&job=" + String(self.request.number) + "&status=" + String(self.status)
        self.make_request(url, info: info, action: true)
    }
    
    //Send response of the interpreter
    func send_response()
    {
        let url = "https://globo.ctitranslators.com/index.php/api/request_app/set_response"
        let info = "&job="+String(self.request.number) + "&response=" + String(self.response)
        self.make_request(url, info: info, action: false)
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
    
    // Make request actio[true = validation, false = response]
    func make_request(_ url:String,info:String, action:Bool)
    {
        //Create request
        let request = NSMutableURLRequest(url: URL(string: url)!)
        
        //Create data to send to request, the token given and the username
        let settings = UserDefaults.standard
        //Data access
        let token = settings.string(forKey: "session")
        let user = settings.string(forKey: "user")
        let data = "user=" + user! + "&session=" + token! + info
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
                }
                DispatchQueue.main.async(execute: { () -> Void in
                    //We have a good response from the server
                    do
                    {
                        //Read response as json
                        let response = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String:Any]
                        print(response)
                        //The status of login
                        let status_response = Int(response["status"] as! NSNumber)
                        let error_status = response["error_status"] != nil ? Int(response["error_status"] as! NSNumber) : 0
                        //action [true->validate, false=>response]
                        if status_response == -1
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
                        //validation
                        //validate job and not job
                        else if status_response == 0 && self.status == 0 && action
                        {
                            _ = self.navigationController?.popViewController(animated: true)
                        }
                        //validate job and job
                        else if status_response == 1 && self.status == 0 && action
                        {
                            self.job_number.text = String(self.request.number)
                            self.job_date.text = self.request.date
                            self.job_company.text = self.request.company
                            self.job_branch.text = self.request.branch
                            self.start.text = self.request.start_time
                            self.end.text = self.request.end_time
                            self.btn_accept.isHidden = false
                            self.btn_reject.isHidden = false
                        }
                        //Error Response
                        else if status_response == -2{
                            //Show validation
                            var message = ""
                            if self.response == 1 {
                                self.response = 2
                                self.send_response()
                            }
                            if error_status == 3 || error_status == 5 {
                                _ = self.navigationController?.popViewController(animated: true)
                                return
                            }
                            else if error_status == 2 || error_status == 4 {
                                message = "The request \(self.request.number) is no longer available."
                            } else if error_status == 6 {
                                message = "You already accepted the request \(self.request.number)."
                            }
                            let confirm = AlertController().alertConfirm("Oops!",msg: message)
                            
                            //If yes then send response
                            confirm.addAction(UIAlertAction(title: "Accept", style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                                //backHome
                                _ = self.navigationController?.popViewController(animated: true)
                            }))
                            self.present(confirm, animated: true, completion: nil)
                        }
                        //Response job
                        else
                        {
                            //response job and get timeclock if request is today
                            if (status_response == 1 && !action)
                            {
                                if(!NSNull().isEqual(response["timeclock"]))
                                {
                                    let timeclock = response["timeclock"]! as! [String: AnyObject]
                                    let nowFormated = DateFormatter()
                                
                                    nowFormated.dateFormat = "YYYY-MM-dd"
                                
                                    let today = nowFormated.string(from: Date())
                                
                                    let start = today + " " + (timeclock["start_time"]!  as! String) + " +0000"
                                    let end = today + " " + (timeclock["end_time"]!  as! String) + " +0000"
                                
                                    nowFormated.calendar = Calendar(identifier: .iso8601)
                                    nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss xx"
                                    nowFormated.locale = Locale(identifier: "en_US_POSIX")
                                
                                    //TIMECLOCK DATA verify if the request's date is today
                                    
                                
                                    let id = Int(timeclock["id"]! as! String)
                                    let request_no = Int(timeclock["id_solicitud"]! as! String)
                                    let branch = timeclock["sucursal"]! as! String
                                    let company = timeclock["empresa"]! as! String
                                    let start_code = timeclock["start_code"]! as! String
                                    let end_code = timeclock["end_code"]! as! String
                                    let status_tc = Int(timeclock["status"]! as! String)
                                
                                    let formatted = DateFormatter()
                                    formatted.dateFormat = "yyyy-MM-dd"
                                    let fecha_date = formatted.date(from: timeclock["fecha"] as! String)!
                                    
                                    let start_date = self.combineDateTime(fecha: fecha_date, times: nowFormated.date(from: start)!)
                                    let end_date = self.combineDateTime(fecha: fecha_date, times: nowFormated.date(from: end)!)
                                    
                                    _ = self.insert_timeclock(NSNumber(integerLiteral: id!), job: NSNumber(integerLiteral: request_no!), start: start_date, end: end_date, branch: branch, company: company, code_end: end_code, code_star: start_code, status: NSNumber(integerLiteral: status_tc!), fecha: fecha_date)
                                }
                            }
                            //Go to nex screen
                            _ = self.navigationController?.popViewController(animated: true)
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
    
    // Insert timeclock of job looked
    func insert_timeclock(_ id:NSNumber, job:NSNumber, start:Date, end:Date, branch: String, company:String, code_end:String, code_star:String, status:NSNumber, fecha:Date)->Bool
    {
        //validate the timeclock does not exists
        //Update timeclock if exists in local DB
        let condition = NSPredicate(format: "job == %@", argumentArray: [job])
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
                    timer!.start_time = start
                    LocalNotification.sharedInstance.removeNotification(timer!)
                    LocalNotification.sharedInstance.addNotification(timer!, option: 0)
                }
                if(timer?.status != 3)
                {
                    timer!.end_time = end
                    LocalNotification.sharedInstance.removeNotification(timer!)
                    if timer?.status == 2
                    {
                        LocalNotification.sharedInstance.addNotification(timer!, option: 1)
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
            timer = NSEntityDescription.insertNewObject(forEntityName: "Timeclock", into: self.managedObjectContext) as? Timeclock
            timer!.id = id
            timer!.job = job
            timer!.branch = branch
            timer!.company = company
            timer!.end_code = code_end
            timer!.start_code = code_star
            timer!.start_time = start
            timer!.end_time = end
            timer!.status = status
            timer!.fecha = fecha
            do
            {
                try managedObjectContext.save()
                let settings = UserDefaults.standard
                let count = settings.string(forKey: "alerts")
            
                let counter = (count == nil ? 0 : Int(count! as String))
            
            
                //Create alert to timeclocks without ipad timeclock.ipad == 1 &&
                if(counter == nil || counter < 64)
                {
                    LocalNotification.sharedInstance.addNotification(timer!,option: 0)
                }
                return true
            }
            catch
            {
                return false
            }
        }
        return true
    }
    
    //delete timeclock specified
    func deleteTimeclock(_ job:NSNumber)
    {
        //Delete timeclocks with status = 1
        let deleteCond = NSPredicate(format: "job == %@", argumentArray: [job])
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Timeclock")
        fetch.predicate = deleteCond
        
        //let instruction = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do
        {
            let tcDelete = try self.managedObjectContext.fetch(fetch) as! [Timeclock]
            for tc in tcDelete
            {
                //Delete local notification
                LocalNotification.sharedInstance.removeNotification(tc)
                self.managedObjectContext.delete(tc)
            }
            try self.managedObjectContext.save()
        }
        catch let error as NSError
        {
            print(error)
        }
        //Delete all local notifications
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    //Go to Request screen, send the job
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        /*if segue.identifier == "backHome"
        {
            
        }*/
    }
}
