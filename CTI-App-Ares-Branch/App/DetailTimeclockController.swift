//
//  DetailTimeclockController.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//
import Foundation
import UIKit
class DetailTimeclockController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    var tc: Timeclock?
    //Components of timeclock
    @IBOutlet weak var tc_job: UILabel!
    @IBOutlet weak var tc_date: UILabel!
    @IBOutlet weak var tc_company: UILabel!
    @IBOutlet weak var tc_branch: UILabel!
    @IBOutlet weak var tc_start: UILabel!
    @IBOutlet weak var tc_end: UILabel!
    @IBOutlet weak var tc_code: UILabel!
    @IBOutlet weak var tc_parking: UIImageView!
    @IBOutlet weak var tc_timesheet: UIImageView!
    
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    //Extras
    @IBOutlet weak var code_lbl: UILabel!
    @IBOutlet weak var read_code: UITextField!
    @IBOutlet weak var start: UIButton!
    @IBOutlet weak var end: UIButton!
    @IBOutlet weak var save_tc: UIButton!
    @IBOutlet weak var end_lbl: UILabel!
    @IBOutlet weak var end_code_lbl: UILabel!
    @IBOutlet weak var tc_end_code_lbl: UILabel!
    
    // Constraints
    @IBOutlet weak var endTimeVHeight: NSLayoutConstraint!      // 53
    @IBOutlet weak var startCodeVHeight: NSLayoutConstraint!    // 53
    @IBOutlet weak var endCodeVHeight: NSLayoutConstraint!      // 53
    @IBOutlet weak var serviceButtonHeight: NSLayoutConstraint! //  65
    @IBOutlet weak var saveButtonHeight: NSLayoutConstraint!    // 38
    
    @IBOutlet weak var readCodeTFWidth: NSLayoutConstraint!     // 60, 156
    
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var qrHeight: NSLayoutConstraint!
    
    
    // Store old edge insets for scroll view
    var edgeInsets: UIEdgeInsets!
    
    //Timeclock ready to send to server
    var sender:String?
    var images = [Data]()
    var name_files =  [String]()
    var name_input = [String]()
    
    //Manager of local database
    let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
    
    
    
    override func viewDidLayoutSubviews() {
        edgeInsets = mainScrollView.contentInset
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        var buttonReject = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        buttonReject.setImage(UIImage(named: "reject.png"), for: .normal)
        buttonReject.addTarget(self, action: #selector(self.reject_job(_:)), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttonReject)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //Load data
        self.tc_job.text = self.tc?.job?.stringValue
        
        //Format to date an time
        let nowFormated = DateFormatter()
        nowFormated.dateFormat = "MMMM dd, YYYY"
        //print(self.tc!.fecha!)
        self.tc_date.text = nowFormated.string(from: self.tc!.fecha!)
        //print(self.tc!.fecha!.addingTimeInterval(60 * 60 * 12))
        self.tc_company.text = self.tc!.company
        self.tc_branch.text = self.tc!.branch
        if(self.tc!.ipad == 0)
        {
            //ACTUAL DATE
            nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss"
            let right_now = nowFormated.string(from: Date())+" +0000"
            //let right_now = nowFormated.string(from: Date())+" +0000"
            nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss xx"
            
            
            let system_date = nowFormated.date(from: nowFormated.string(from: Date()))
            
            //Start job
            if self.tc!.status == 1
            {
                let start = self.tc!.start_time!
                let difference_time = system_date!.timeIntervalSince(start as Date)
                
                nowFormated.dateFormat = "HH:mm"
                self.tc_start.text = nowFormated.string(from: Date())
                print(self.tc!.fecha!)
                let fecha_interval = self.tc!.fecha!.timeIntervalSince(Date())
                //Give permission to start
                if fecha_interval >= 0 {
                    self.read_code.isHidden = false
                    self.start.isHidden = false
                    serviceButtonHeight.constant = 65
                    
                    self.read_code.isEnabled = false
                    self.start.isEnabled = false
                    
                    let formatted = DateFormatter()
                    formatted.dateFormat = "MMMM dd"
                    let wait_date = formatted.string(from: self.tc!.fecha!)
                    let alert = AlertController().alertError("Please wait", msg: "You have to wait until \(wait_date)",opt: "Accept")
                    self.present(alert, animated: true, completion: nil)
                }
                else if difference_time >= (-5*60)
                {
                    self.tc_code.text = self.tc?.start_code
                    self.tc_code.isHidden = false
                    self.code_lbl.isHidden = false
                    startCodeVHeight.constant = 53
                    
                    self.read_code.isHidden = false
                    self.start.isHidden = false
                    serviceButtonHeight.constant = 65
                }
                    //The user doesn's have permission to start
                else
                {
                    self.read_code.isHidden = false
                    self.start.isHidden = false
                    serviceButtonHeight.constant = 65
                    
                    self.read_code.isEnabled = false
                    self.start.isEnabled = false
                    
                    var waiting = difference_time/(difference_time < 0 ? -60.0 : 60.0)
                    waiting = waiting - 5.0;
                    let alert = AlertController().alertError("Please wait",msg: "\(Int(round(waiting))) minutes to start your assignment",opt: "Accept")
                    self.present(alert, animated: true, completion: nil)
                }
                
                readCodeTFWidth.constant = 156
            }
                //Finalize job
            else if self.tc!.status == 2
            {
                nowFormated.dateFormat = "HH:mm"
                self.tc_start.text = nowFormated.string(from: self.tc!.start_time! as Date)
                nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss"
                let str = nowFormated.string(from: self.tc!.start_time! as Date)+" +0000"
                
                //print(difference_time)
                
                nowFormated.timeZone = TimeZone(abbreviation: "GMT")
                let end = nowFormated.string(from: self.tc!.end_time! as Date)+" +0000"
                
                
                nowFormated.calendar = Calendar(identifier: .iso8601)
                nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss"
                nowFormated.locale = Locale(identifier: "en_US_POSIX")
                nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss xx"
                let end_time = nowFormated.date(from: end)
                let just_end = system_date!.timeIntervalSince(end_time!)
                
                //get difference since start time to now
                
                let start_tc = nowFormated.date(from: str)
                let difference_time = system_date!.timeIntervalSince(start_tc!)
                
                //Hide star button
                self.start.isHidden = true
                serviceButtonHeight.constant = 0
                
                //Can the user finish the job?
                if difference_time >= (60*15) || just_end >= 0
                {
                    //Show the options to end code
                    self.read_code.placeholder = "Enter your code here"
                    self.code_lbl.isHidden = false
                    self.code_lbl.text = "End Code"
                    self.tc_code.isHidden = false
                    self.tc_code.text = self.tc?.end_code
                    startCodeVHeight.constant = 53
                    
                    self.read_code.isHidden = false
                    self.end.isHidden = false
                    serviceButtonHeight.constant = 65
                    
                    self.read_code.isEnabled = true
                    self.end.isEnabled = true
                }
                else
                {
                    self.read_code.isHidden = false
                    self.end.isHidden = false
                    self.read_code.isEnabled = false
                    self.end.isEnabled = false
                }
                
                readCodeTFWidth.constant = 156
            }
                //Job finished
            else
            {
                //start time and end time
                nowFormated.dateFormat = "HH:mm"
                self.tc_start.text = nowFormated.string(from: self.tc!.start_time! as Date)
                self.tc_end.text = nowFormated.string(from: self.tc!.end_time! as Date)
                //hide start button
                self.start.isHidden = true
                serviceButtonHeight.constant = 0
                
                //Show timesheet and parking button and other options
                self.tc_parking.isHidden = false
                self.tc_timesheet.isHidden = false
                
                self.save_tc.isHidden = false
                saveButtonHeight.constant = 38
                
                self.end_lbl.isHidden = false
                self.tc_end.isHidden = false
                endTimeVHeight.constant = 53
                
                //Actions to parking and timesheet buttons
                let tap = UITapGestureRecognizer(target: self, action: #selector(DetailTimeclockController.imageTapped(_:)))
                
                let tap2 = UITapGestureRecognizer(target: self, action: #selector(DetailTimeclockController.imageTapped(_:)))
                self.tc_parking.addGestureRecognizer(tap)
                self.tc_parking.isUserInteractionEnabled = true
                
                
                self.tc_timesheet.addGestureRecognizer(tap2)
                self.tc_timesheet.isUserInteractionEnabled = true
            }
            
            let tap:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DetailTimeclockController.dismissKeyboard))
            view.addGestureRecognizer(tap)
            
            qrHeight.constant = 0
        }
        else
        {
            nowFormated.dateFormat = "HH:mm"
            self.tc_start.text = nowFormated.string(from: self.tc!.start_time!)
            self.tc_end.text = nowFormated.string(from: self.tc!.end_time!)
            
            self.tc_code.text = self.tc!.start_code!
            self.code_lbl.isHidden = false
            self.tc_code.isHidden = false
            startCodeVHeight.constant = 53
            
            self.tc_end_code_lbl.text = self.tc!.end_code!
            self.end_code_lbl.isHidden = false
            self.tc_end_code_lbl.isHidden = false
            endCodeVHeight.constant = 53
            
            self.end_lbl.isHidden = false
            self.tc_end.isHidden = false
            endTimeVHeight.constant = 53

            func documentsPathForFileName(name: String) -> String {
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsPath = paths[0]
                
                return documentsPath.appending("/" + name)
            }
            
            let settings = UserDefaults.standard
            if settings.string(forKey: "qr") != nil {
                qrImageView.image = UIImage(contentsOfFile: documentsPathForFileName(name: "qr.jpg"))
            } else {
                qrHeight.constant = 0
            }
        }
        
        self.view.setNeedsLayout()
    }
    
    //Hide keyboard when touch anywhere out of it
    func dismissKeyboard()
    {
        view.endEditing(true)
    }
    
    //Start code
    @IBAction func start_service(_ sender: UIButton)
    {
        if self.tc == nil {
            let alert = UIAlertController(title: "Error", message: "This request is invalid.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if self.tc!.start_code == nil {
            let alert = UIAlertController(title: "Error", message: "This request is invalid. Wrong start code.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        //if the code is right then update timeclock
        if self.validate_code(self.read_code.text!, right_code: self.tc!.start_code!)
        {
            //Update start time
            if self.set_date(true)
            {
                //LocalNotification.sharedInstance.addNotification(self.tc!,option: 0)
                //LocalNotification.sharedInstance.addNotification(self.tc!,option: 1)
//                self.performSegue(withIdentifier: "return_timeclocks", sender: self)
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    //End Code
    @IBAction func finish_service(_ sender: UIButton)
    {
        //if code is right then update timeclock, end time
        if self.validate_code(self.read_code.text!, right_code: self.tc!.end_code!)
        {
            //Set end time
            if self.set_date(false)
            {
                //Hide code reader, code label and timeclock's code
                self.tc_code.isHidden = true
                self.code_lbl.isHidden = true
                startCodeVHeight.constant = 0
                
                self.read_code.isHidden = true
                readCodeTFWidth.constant = 60
            
                //Remove the local notifications associated to the timeclock
                LocalNotification.sharedInstance.removeNotification(self.tc!)
            
                //Show start and end time
                let nowFormated = DateFormatter()
                nowFormated.dateFormat = "HH:mm"
                self.tc_start.text = nowFormated.string(from: self.tc!.start_time! as Date)
                self.tc_end.text = nowFormated.string(from: self.tc!.end_time! as Date)
                
                //Show options to send the info to the server
                self.start.isHidden = true
                self.end.isHidden = true
                self.tc_parking.isHidden = false
                self.tc_timesheet.isHidden = false
                self.save_tc.isHidden = false
                saveButtonHeight.constant = 38
                
                self.end_lbl.isHidden = false
                self.tc_end.isHidden = false
                endTimeVHeight.constant = 53
            
            
                let tap = UITapGestureRecognizer(target: self, action: #selector(DetailTimeclockController.imageTapped(_:)))
                let tap2 = UITapGestureRecognizer(target: self, action: #selector(DetailTimeclockController.imageTapped(_:)))
                
                self.tc_parking.addGestureRecognizer(tap)
                self.tc_parking.isUserInteractionEnabled = true
            
                self.tc_timesheet.addGestureRecognizer(tap2)
                self.tc_timesheet.isUserInteractionEnabled = true
                
                self.view.setNeedsLayout()
            }
        }
        
        
    }
    
    //Reject Job
    @IBAction func reject_job(_ sender: AnyObject)
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
    
    func send_response()
    {
        let url = "https://globo.ctitranslators.com/index.php/api/request_app/set_response"
        let info = "&job=\(Int((self.tc?.job)!))&response=2"
        self.make_request(url, info: info, action: false)
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
            DispatchQueue.main.async {
                _ = self.navigationController?.popViewController(animated: true)
            }
        })
        
        task.resume()
    }
    
    //Validate code
    func validate_code(_ code:String, right_code:String)->Bool
    {
        if code == right_code
        {
            return true
        }
        //code is wrong
        else
        {
            let alert = AlertController().alertError("Wrong code",msg: "Please verify your code and try again",opt: "Accept")
            self.present(alert, animated: true, completion: nil)
        }
        return false
    }
    
    //Take a picture
    func imageTapped(_ gestureRecognizer: UITapGestureRecognizer)
    {
        //Verify that the tap is joined to ui image view
        if let imgview = gestureRecognizer.view as? UIImageView
        {
            //There is a camera?
            if UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.rear) || UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.front)
            {
                //Who is the sender?
                self.sender = imgview.restorationIdentifier
                
                //Open camera
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = .camera
                picker.allowsEditing = false
                self.present(picker, animated: true, completion: nil)
            }
        }
    }
    
    //Show Image taken, delegate of picker controller
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?)
    {
        //Check who is the sender
        if self.sender == "parking"
        {
            self.tc_parking.image = UIImage(named: "parking.png")
            
            self.images.append(UIImageJPEGRepresentation(image,0.5)!)
            self.name_files.append("parking.jpg")
            self.name_input.append("parking")
        }
        else
        {
            self.self.tc_timesheet.image = UIImage(named: "Timesheet.png")
            
            self.images.append(UIImageJPEGRepresentation(image, 0.5)!)
            self.name_files.append("timesheet.jpg")
            self.name_input.append("timesheet")
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //Save data----Send data to server
    @IBAction func save_timeclock(_ sender: UIButton)
    {
        if Reachability.isConnectedToNetwork()
        {
            //Send data to server
            let settings = UserDefaults.standard
            //Data access
            let token = settings.string(forKey: "session")
            let user = settings.string(forKey: "user")
            
            //Create request
            let request = NSMutableURLRequest(url: URL(string: "https://globo.ctitranslators.com/index.php/api/timeclock_app/updateTimeclock")!)
            //Create data to send to timeclock
            let nowFormated = DateFormatter()
            nowFormated.dateFormat = "HH:mm"
            let start = nowFormated.string(from: self.tc!.start_time! as Date)
            //nowFormated.timeZone = NSTimeZone(abbreviation: "GMT")
            let end = nowFormated.string(from: self.tc!.end_time! as Date)
            let job = self.tc!.job?.stringValue
            let id = self.tc!.id?.stringValue
            
            let param = ["session":token!,
                         "user":user!,
                         "start":start,
                         "end":end,
                         "job":job!,
                         "id":id!]
            
            let boundary = self.generateBoundaryString()
            
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField:"Content-Type")

            //Define method Post
            request.httpMethod = "POST"
            
            
            //Send data to request
            request.httpBody = self.createBodyWithParameters(param, nameFiles: name_files, nameInput: name_input, images: images, boundary: boundary)
            
            //Start conection whit server
            let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
                    //Error in request
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
                            let response = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String:Any]
                            
                            //status of session and action
                            let status = Int(response["status"] as! NSNumber)
                            //there is an error in the server
                            if status == 0
                            {
                                let alert = AlertController().alertError("Error",msg: "Try again, please",opt: "Accept")
                                self.present(alert, animated: true, completion: nil)
                            }
                            //The session doesn't exist
                            else if status == -1
                            {
                                //Remove local storage
                                settings.removeObject(forKey: "user")
                                settings.removeObject(forKey: "password")
                                settings.removeObject(forKey: "session")
                                settings.removeObject(forKey: "profile")
                                settings.removeObject(forKey: "interprete")
                                settings.removeObject(forKey: "qr")
                                settings.synchronize()
                                //redirect to login
                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                let vc = storyboard.instantiateViewController(withIdentifier: "login")
                                self.present(vc, animated: true, completion: nil)
                                TimeclockController.deleteTimeclocks()
                            }
                            //Timeclock updated
                            else
                            {
                                //Delete object
                                self.managedObjectContext.delete(self.tc!)
                                try self.managedObjectContext.save()
                                _ = self.navigationController?.popViewController(animated: true)
                                //Redirect to home
//                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                                let vc = storyboard.instantiateViewController(withIdentifier: "home")
//                                self.present(vc, animated: true, completion: nil)
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
        else
        {
            let alert = AlertController().alertError("Network error",msg: "Please verify your network connection",opt: "Accept")
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //Generate boundary to send photos
    func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    //Create data to send the server
    func createBodyWithParameters(_ parameters: [String: String]?, nameFiles: [String]?, nameInput:[String]?, images: [Data], boundary: String) -> Data {
        //data to send
        let body = NSMutableData();
        //If there are parameters
        if parameters != nil
        {
            //iterate parameters
            for (key, value) in parameters!
            {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }
        //There is at least one image
        if self.images.count > 0
        {
            //Iterate images
            for i in 0 ..< self.images.count
            {
                //Get data of image to send the server
                let filename = self.name_files[i]   //name of file
                let image = self.images[i]          //image
                let mimetype = "image/jpg"          //mimetype
                
                let input = self.name_input[i]      //name of input
                
                //Add image to body of data
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(input)\"; filename=\"\(filename)\"\r\n")
                body.appendString("Content-Type: \(mimetype)\r\n\r\n")
                body.append(image)
                body.appendString("\r\n")
            }
        }
        
        body.appendString("--\(boundary)--\r\n")
        
        return body as Data
    }

    //Set date
    func set_date(_ opt:Bool)->Bool
    {
        //opt = true -> start; opt = false ->end
        let nowFormated = DateFormatter()
        nowFormated.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let date = nowFormated.string(from: Date())
        let date_set = nowFormated.date(from: date)
        if opt
        {
            self.tc!.status = 2
            self.tc!.start_time = date_set
        }
        else
        {
            self.tc!.status = 3
            self.tc!.end_time = date_set
        }
        do
        {
            try self.managedObjectContext.save()
            return true
        }
        catch
        {
            print("ERROR WHEN UPDATING TIMECLOCK")
            return false
        }
    }
    
    @IBAction func dismissView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
//        if segue.identifier == "return_timeclocks"
//        {
//            //Set view to see
//            let home = segue.destination as! HomeController
//            
//            home.index = 1
//        }
    }
    
    // MARK: Keyboard Notifications
    func keyboardWillShow(notification:NSNotification){
        //give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.mainScrollView.contentInset
        
        contentInset.bottom = keyboardFrame.size.height
        self.mainScrollView.contentInset = contentInset
        
        contentInset.bottom -= self.tabBarController!.tabBar.frame.size.height
        self.mainScrollView.scrollIndicatorInsets = contentInset
    }
    
    func keyboardWillHide(notification:NSNotification){
        self.mainScrollView.contentInset = edgeInsets
        
//        contentInset.bottom -= self.tabBarController!.tabBar.frame.size.height
        self.mainScrollView.scrollIndicatorInsets = edgeInsets
    }
}
extension NSMutableData
{
    
    func appendString(_ string: String)
    {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
