//
//  AlertTimeController.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//
import Foundation
import UIKit
class AlertTimeController: UIViewController
{
    var interpreter: String = ""
    var job: NSNumber = 0
    
    var inte: NSNumber = 0
    
    @IBOutlet weak var timerExtra: UIDatePicker!
    @IBOutlet weak var lblInte: UILabel!
    
    override func viewWillAppear(_ animated: Bool)
    {
        self.lblInte.text = self.interpreter
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "HH:mm:ss"
        
        let date = dateFormatter.date(from: "00:00")
        
        self.timerExtra.date = date!
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.navigationItem.title = "10 minutes"
    }
    
    
    @IBAction func GiveTime(_ sender: UIButton)
    {
        let url = "https://globo.ctitranslators.com/index.php/api/extra_time/send_time_response"
        
        let date = self.timerExtra.date
        
        let calendar = Calendar.current
        
        let components = (calendar as NSCalendar).components([NSCalendar.Unit.hour, NSCalendar.Unit.minute] , from: date)
        
        let seconds = (components.hour! * 60 * 60) + (components.minute! * 60)
        
        let info =  "time=" + String(seconds) + "&job=" + String(describing: self.job) + "&inte=" + String(describing: self.inte)
        
        if Reachability.isConnectedToNetwork()
        {
            self.connectURL(url, info: info)
        }
        else
        {
            let alert = AlertController().alertError("Network error",msg: "Please verify your network connection",opt: "Accept")
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func RejectTime(_ sender: UIButton)
    {
        let url = "https://globo.ctitranslators.com/index.php/api/extra_time/send_time_response"
        let info =  "time=0&job=" + String(describing: self.job) + "&inte=" + String(describing: self.inte)
        
        if Reachability.isConnectedToNetwork()
        {
            self.connectURL(url, info: info)
        }
        else
        {
            let alert = AlertController().alertError("Network error",msg: "Please verify your network connection",opt: "Accept")
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    func connectURL(_ url: String, info: String)
    {
        //Create request
        let request = NSMutableURLRequest(url: URL(string: url)!)
        
        //Create data to send to request, the token given and the username
        let settings = UserDefaults.standard
        //Data access
        let token = settings.string(forKey: "session")
        let user = settings.string(forKey: "user")
        var data = ""
        if info == ""
        {
            data = "user=" + user! + "&session=" + token!
        }
        else
        {
            data = info + "&user=" + user! + "&session=" + token!
        }
        
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
                                         
                        //Go to nex screen
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "login")
                        self.present(vc, animated: true, completion: nil)
                        TimeclockController.deleteTimeclocks()
                    }
                    //Go back
                    else if status > 0
                    {
                        self.dismiss(animated: true, completion: nil)
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
}
