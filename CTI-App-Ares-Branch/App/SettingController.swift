//
//  SettingController.swift
//  App
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//
import Foundation
import UIKit
import CoreData

class SettingController: UITableViewController
{
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "option", for: indexPath) as! OptionCell
        
        cell.option.addTarget(self, action: #selector(SettingController.logout_session(_:)), for: .touchUpInside)
        cell.option.tag = indexPath.row
        return cell as UITableViewCell
    }

    //Button to logout
    func logout_session(_ sender: UIButton)
    {
        let confirm = AlertController().alertConfirm("Logout Confirmation",msg: "Are you sure you want to log out?")
        
        confirm.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
            if(Reachability.isConnectedToNetwork())
            {
                self.logout()
            }
            else
            {
                let alert = AlertController().alertError("Network error",msg: "Please verify your network connection",opt: "Accept")
                self.present(alert, animated: true, completion: nil)
            }
        }))
        confirm.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: nil))
        self.present(confirm, animated: true, completion: nil)
    }
    
    //Delete token given in the server and all configuration in the iphone
    func logout()
    {
        //Create request
        let request = NSMutableURLRequest(url: URL(string: "https://globo.ctitranslators.com/index.php/api/user_app/logout")!)
        
        //Create data to send to request, the token given and the username
        let settings = UserDefaults.standard
        //Data access
        let token = settings.string(forKey: "session")
        let user = settings.string(forKey: "user")
        let device = settings.string(forKey: "deviceToken")
        
        let data = "user=" + user! + "&session=" + token! + "&device=" + device!
        
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
                        if status != 1
                        {
                            //Go to next screen
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "login")
                            self.present(vc, animated: true, completion: nil)
                        }
                            //print("first action \(response)")
                        else
                        {
                            //print("LOGEADO")
                            self.delete_tc_logout()
                            //Go to next screen
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "login")
                            self.present(vc, animated: true, completion: nil)
                        }
                        settings.removeObject(forKey: "user")
                        settings.removeObject(forKey: "password")
                        settings.removeObject(forKey: "session")
                        settings.removeObject(forKey: "profile")
                        settings.removeObject(forKey: "interprete")
                        settings.removeObject(forKey: "qr")
                        settings.synchronize()
                        
                        TimeclockController.deleteTimeclocks()
                    }
                    catch
                    {
                        print("error JSON: \(error)")
                    }
                })
        })            

        task.resume()
    }
    
    //Delete all timeclocks
    func delete_tc_logout()
    {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Timeclock")
        let instruction = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do
        {
            try self.managedObjectContext.execute(instruction)
        }
        catch let error as NSError
        {
            print(error)
        }
    }
}
