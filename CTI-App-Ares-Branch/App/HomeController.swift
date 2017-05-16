//
//  HomeController.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation
import UIKit
class HomeController: UITabBarController
{
//    var index: Int = 0
    
    override func viewWillAppear(_ animated: Bool)
    {
        //Get profile of user to customize
        let settings = UserDefaults.standard
        let profile = Int(settings.string(forKey: "profile")!)
        
        //If not interpreter then delete timeclock
        if(profile != 4)
        {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "settings")
            let vc2 = storyboard.instantiateViewController(withIdentifier: "contacts")
            //Client and Admin only can access the chat and settings
            let items = [vc2, vc]
            self.setViewControllers(items, animated: true)
        }
        self.tabBar.tintColor = UIColor.white
//        self.selectedIndex = self.index
//        print(self.index)
    }
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(true)
    }
}
