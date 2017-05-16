//
//  ChatController.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation
import UIKit
import Firebase
class ChatController: UITableViewController
{
    //Contact
    var contacts:[Contact] = []
    var admin = Contact(number: 1, nameContact: "Admin", entity: "user")
    //Before appear load contacts
    override func viewWillAppear(_ animated: Bool)
    {
        self.contacts.removeAll()
        
        if(Reachability.isConnectedToNetwork())
        {
            //Get all the job from database
            self.get_contacts()
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
    
    
    //Delegate teableViewController
    //Return total of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //Return the total of cells
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contacts.count
    }
    
    //Cell of contact
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "contact", for: indexPath) as! ContactCell
        //print(self.contacts.count)
        if indexPath.row < self.contacts.count
        {
            cell.contact = self.contacts[indexPath.row]
            cell.load()
        }
        return cell
    }
    
    //Add segue to row of table
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let cell = self.tableView.cellForRow(at: indexPath) as! ContactCell
        performSegue(withIdentifier: "view_msgs", sender: cell)
    }
    
    //Go to Request screen, send the job
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "view_msgs"
        {
            let cell = sender as? UITableViewCell
            let index = tableView.indexPath(for: cell!)
            //Send the job that the user wants to look
            let chat = segue.destination as! MessagesViewController
            chat.receiver = self.contacts[(index?.row)!]
        }
    }
    
    //Get the Contacts that the user can to talk
    func get_contacts()
    {
        _ = FIRDatabase.database().reference(withPath: "users")
    }
}
