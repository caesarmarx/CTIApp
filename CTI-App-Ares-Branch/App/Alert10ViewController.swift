//
//  Alert10ViewController.swift
//  CTI Translators
//
//  Created by Neo on 3/3/17.
//  Copyright © 2017 CTI. All rights reserved.
//

import UIKit

class Alert10ViewController: UIViewController {
    
    var tc: Timeclock!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "10 minutes left"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

    @IBAction func accept(_ sender: Any) {
        if(Reachability.isConnectedToNetwork())
        {
            //Get chat of users
            let url = "https://globo.ctitranslators.com/index.php/api/extra_time/ask_time"
            let info = "job=\(tc.job!)"
            self.connectURL(url, info: info)

            LocalNotification.sharedInstance.removeNotification(tc!)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func reject(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
                    //The status of login
                    let status = Int(response["status"] as! NSNumber)
                    print(response)
                    //Notificacion sended
                    if status != 1
                    {
                        print(response)
                        //Notification to five minutes
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
