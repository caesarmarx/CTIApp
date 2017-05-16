//
//  LoginViewController.swift
//  App
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//
import Foundation
import UIKit
import Firebase

class LoginViewController: UIViewController
{
    @IBOutlet weak var mail: UITextField!
    @IBOutlet weak var pass: UITextField!
    
    func documentsPathForFileName(name: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsPath = paths[0] 
        
        return documentsPath.appending("/" + name)
    }
    
    @IBAction func validate_login(sender: UIButton)
    {
        var title = "Network error"
        var msg = "Please verify your network connection!"
        var opt = "Accept"
        
        if Reachability.isConnectedToNetwork()
        {
            //Not errors
            var status = -2
            
            //NOT INFORMATION
            if(self.mail.text == "" && self.pass.text == "")
            {
                title = "Login error"
                msg = "Please verify your username and password"
                opt = "Accept"
                status = -1
                let alert = AlertController().alertError(title,msg: msg,opt: opt)
                self.present(alert, animated: true, completion: nil)
            }
            else if status == -2
            {
                let settings = UserDefaults.standard
                //Create request
                let request = NSMutableURLRequest(url: NSURL(string: "https://globo.ctitranslators.com/index.php/login/check_access")! as URL)
                //Create data to send to request
                let deviceToken = settings.string(forKey: "deviceToken")
                
                var data = "usuario=" + self.mail.text!
                data = data + "&password=" + self.pass.text! + "&prmorigen=app"
                data = data + "&device=" + deviceToken!
                
                //Define method Post
                request.httpMethod = "POST"
                //Send data to request
                request.httpBody = data.data(using: String.Encoding.utf8)
                
                //Start conection whit server
                let task = URLSession.shared.dataTask(with: request as URLRequest)
                    {
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
                        DispatchQueue.main.sync(execute: { () -> Void in
                            //We have a good response from the server
                            do
                            {
                                //Read response as json
                                let response = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String:AnyObject]
                                //The status of login
                                print("\(response)")
                                status = Int(response["status"] as! NSNumber)
                                if status != 1
                                {
                                    title = "Login error"
                                    msg = "Please enter a valid username and password."
                                    opt = "Accept"
                                }
                                else
                                {
                                    //print("LOGEADO")
                                    //let settings = NSUserDefaults.standardUserDefaults()
                                    settings.set(self.mail.text, forKey:"user")
                                    settings.set(self.pass.text, forKey:"password")
                                    settings.set(response["session"] as! String, forKey:"session")
                                    settings.set(response["profile"] as! String, forKey:"profile")
                                    settings.set(Int(response["interprete"] as! String), forKey: "interprete")
                                    
                                   if response["profile"] as! String == "4" {
                                        do  {
                                            let qrImage = try UIImage(data: Data(contentsOf: URL(string: response["qr"] as! String)!))!
                                            // Get image data. Here you can use UIImagePNGRepresentation if you need transparency
                                            let imageData = UIImageJPEGRepresentation(qrImage, 1)!
                                            
                                            // Get image path in user's folder and store file with name image_CurrentTimestamp.jpg (see documentsPathForFileName below)
                                            let imagePath = self.documentsPathForFileName(name: "qr.jpg")
                                            
                                            // Write image data to user's folder
                                            try imageData.write(to: URL(fileURLWithPath: imagePath), options: Data.WritingOptions.atomic)
                                            
                                            settings.set(imagePath, forKey: "qr")
                                        } catch {
                                            
                                        }
                                    } else {
                                        settings.removeObject(forKey: "qr")
                                        
                                    }
                                    
                                    settings.synchronize()
                                    //Go to nex screen
                                    
                                    FIRAuth.auth()?.signIn(withEmail: self.mail.text!, password: self.pass.text!, completion: { (user, error) in
                                        if error != nil {
                                            print(error!.localizedDescription)
                                            return
                                        }
                                        let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
                                        changeRequest?.displayName = response["profile"] as! String?
                                        changeRequest?.commitChanges() { (error) in
                                            
                                        }
                                    })
                                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                    let vc = storyboard.instantiateViewController(withIdentifier: "home")
                                    self.present(vc, animated: true, completion: nil)
                                    
                                }
                            }
                            catch
                            {
                                print("error JSON: \(error)")
                            }
                            //print("second action \(status)")
                            //If status is true then save the credentials and go to next screen
                            if status == 0
                            {
                                let alert = AlertController().alertError(title,msg: msg,opt: opt)
                                self.present(alert, animated: true, completion: nil)
                            }
                        })
                    }
                task.resume()
            }
        }
        //NOT INTERNET
        else
        {
            let alert = AlertController().alertError(title,msg: msg,opt: opt)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        let tap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    //Hide keyboard when touch anywhere out of it
    func dismissKeyboard()
    {
        view.endEditing(true)
    }
}
