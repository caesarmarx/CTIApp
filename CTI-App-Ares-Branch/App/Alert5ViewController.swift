//
//  Alert5ViewController.swift
//  CTI Translators
//
//  Created by Neo on 3/3/17.
//  Copyright © 2017 CTI. All rights reserved.
//

import UIKit

class Alert5ViewController: UIViewController {

    var tc: Timeclock!
    @IBOutlet weak var phoneLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "5 minutes left"
        
        phoneLabel.text = tc.telephone
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(Alert5ViewController.close))
    }
    
    func close() {
        dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func call(_ sender: Any) {
        if tc!.telephone !=  nil && tc!.telephone !=  ""
        {
            let url = URL(string: "tel://" + tc!.telephone!)!
            UIApplication.shared.openURL(url)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
