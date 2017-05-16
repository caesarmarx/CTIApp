//
//  RequestsViewController.swift
//  App
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//
import Foundation
import UIKit
class RequestsViewController: UITableViewController
{
    //Request into database
    var requests:[Job] = []
    
    //Construct
    override func viewWillAppear(_ animated: Bool)
    {
        if(Reachability.isConnectedToNetwork())
        {
            //Get all the job from database
            self.get_jobs()
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
      
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    //Return total of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //Return the total of cells
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.requests.count
    }
    
    //Place every job on requests in the cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "job", for: indexPath) as! RequestCell
        if indexPath.row < self.requests.count
        {
            cell.request = self.requests[indexPath.row]
            cell.load()
        }
        return cell
    }
    
    //Add segue to row of table
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let cell = self.tableView.cellForRow(at: indexPath) as! RequestCell
        performSegue(withIdentifier: "job_detail", sender: cell)
    }
    
    //Go to Request screen, send the job
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "job_detail"
        {
            let cell = sender as? UITableViewCell
            let index = tableView.indexPath(for: cell!)
            //Send the job that the user wants to look
            let detail = segue.destination as! RequestViewController
            detail.request = self.requests[(index?.row)!]
        }
    }
    
    //Get the jobs into server's database
    func get_jobs()
    {
        //Create request
        let request = NSMutableURLRequest(url: URL(string: "https://globo.ctitranslators.com/index.php/api/request_app/requests_unresponse")!)
        
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
                        let response = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String:AnyObject]
                        //The status of login
                        print(response)
                        
                        let status = response["status"] as! NSNumber
                        //NO TOKEN INTO DB
                        if status != 1
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
                            //print("first action \(response)")
                        else
                        {
                            //print(response)
                            let has_items = response["total"] as! Int
                            
                            self.requests.removeAll()
                            
                            if has_items > 0
                            {
                                let jobs = response["jobs"]! as! [[String: AnyObject]]
                                
                                for new_job in jobs
                                {
                                    print(new_job)
                                    self.requests.append(Job(data: new_job as NSDictionary))
                                }
                            }
                            self.tableView.reloadData()
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
