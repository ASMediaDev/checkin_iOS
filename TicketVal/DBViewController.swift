//
//  DBViewController.swift
//  TicketVal
//
//  Created by Alex Seitz on 21.11.16.
//  Copyright © 2016 Alex. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import RealmSwift
import Locksmith


class DBViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource  {
    
    
    
//Variables&Outlets
    
    @IBOutlet weak var attendeesCount: UITextView!
    
    @IBOutlet weak var tableViewTitle: UITextView!
    
    @IBOutlet weak var attendeesTableView: UITableView!
    
    @IBOutlet weak var eventpicker: UIPickerView!
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var attendeesTextView: UITextView!
    
    @IBOutlet weak var status_rect: UIView!
   
    
    
    var placementAnswer = 0;
    
    var eventarray = [String]()
    
    var eventsdictionary = NSDictionary()
    
    var attendees = [String]()
    
    var attendeesdictionary = NSDictionary()
    
    //Time measurement test
    
    var startTime: TimeInterval = 0
    var endTime: TimeInterval = 0
   
//Buttons
   
    @IBAction func logoutBtn(_ sender: AnyObject) {
        
        do{
            try Locksmith.deleteDataForUserAccount(userAccount: "TicketVal")
            try Locksmith.deleteDataForUserAccount(userAccount: "TicketValAPI")
        }catch{
        
        }
        let loginPage = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController")
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = loginPage
        
    }
    
    @IBAction func scanButton(_ sender: Any) {

            self.performSegue(withIdentifier:"dbview_to_scan", sender: nil)


    }
    
    
    @IBAction func insertAttendeesButton(_ sender: Any) {
        
        let alertController = UIAlertController(title: "WARNUNG", message: "Durch die Synchronisation werden alle bisher importierten Datensätze gelöscht!", preferredStyle: .alert)
        
        
        let okAction = UIAlertAction(title: "Fortfahren", style: .default) { action in

            self.insertAttendees(eventId: (self.placementAnswer)+1)
            print("Attendees inserted")
            
        }
        alertController.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel) { action in
            
        }
        alertController.addAction(cancelAction)
        
        
        
        self.present(alertController, animated: true) {
            // ...
        }
    }
    
    @IBAction func truncateDatabase(_ sender: Any) {
        
        let alertController = UIAlertController(title: "WARNUNG", message: "Alle Datensätze in der Datenbank werden gelöscht", preferredStyle: .alert)
        
        
        let okAction = UIAlertAction(title: "Fortfahren", style: .default) { action in
            
            self.clearDataStore()
            self.attendeesCount.text = "Anzahl der Gäste in der Datenbank: \n \(self.countAttendees())"
            
        }
        alertController.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .cancel) { action in
            
        }
        alertController.addAction(cancelAction)
        
        
        
        self.present(alertController, animated: true) {
            // ...
        }
    }
    
    @IBAction func openpicker(_ sender: Any) {
        
        self.eventpicker.reloadAllComponents()
        self.view.viewWithTag(3)?.isHidden = true
        self.view.viewWithTag(1)?.isHidden = false
    }
    
    @IBAction func selectevent(_ sender: Any) {
        label.text = "Gewähltes Event: \(eventarray[placementAnswer])"
        tableViewTitle.text = "Verfügbare Datensätze für:\n\(eventarray[placementAnswer])"
        self.view.viewWithTag(1)?.isHidden = true
        UserDefaults.standard.setValue(placementAnswer, forKey: "selectedEvent")
        print(UserDefaults.standard.value(forKey: "selectedEvent")!)
        self.view.viewWithTag(3)?.isHidden = false
        
        attendees = []
        
        let api = TicketValAPI()
        api.getAttendees(eventId: (placementAnswer)+1) {(error, attendees) in
            if let error = error{
                print(error)
            }else {
                //print("Content:")
                for attendee in attendees {
                    self.attendees.append(attendee.firstname + " " + attendee.lastname)
                }
                
                print(self.attendees)
                DispatchQueue.main.async {
                    self.attendeesTableView.reloadData()
                }
            }
        }
    }
    
//Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.view.viewWithTag(1)?.isHidden = true //picker ausblenden
        eventpicker.delegate = self
        eventpicker.dataSource = self
        
        let api = TicketValAPI()
        api.getEvents() {(error, events) in
            if let error = error{
                print(error)
            }else {
                print("Content:")
                print(events[0].startdate)
                
                for event in events {
                    
                    self.eventarray.append(event.title)
                    print(event.title)
                    
                    
                }
            }
        }
        
        if(countAttendees()==0){
            status_rect.backgroundColor = UIColor.red
        }else{
            status_rect.backgroundColor = UIColor.green
        }
        
        attendeesCount.text = "Anzahl der Gäste in der Datenbank: \n \(countAttendees())"
    }
    
 

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//pickerview methods

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return eventarray[row]
        
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return eventarray.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        placementAnswer = row
    }
    
 //tableview methods
    
    func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int
    {
        return attendees.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mycell", for: indexPath)
        
        
        if (attendees.isEmpty){
            
            cell.textLabel?.text = "empty"
        } else {
            
            cell.textLabel?.text = attendees[indexPath.item]
            
        }
        return cell
    }
    
    //Realm methods
    
    func clearDataStore(){
        
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
        DispatchQueue.main.async{
            self.status_rect.backgroundColor = UIColor.red
    }
        
    }
  
    
    func insertAttendees(eventId: Int){
       
        let t1 = mach_absolute_time()
        
        
        
        let api = TicketValAPI()
        api.getAttendees(eventId: eventId) {(error, attendees) in
            if let error = error{
                print(error)
            }else {
                let t11 = mach_absolute_time()
                
                self.clearDataStore()
                
                let t21 = mach_absolute_time()
                
                let elapsed2 = t21 - t11
                var timeBaseInfo2 = mach_timebase_info_data_t()
                mach_timebase_info(&timeBaseInfo2)
                let elapsedNano2 = elapsed2 * UInt64(timeBaseInfo2.numer) / UInt64(timeBaseInfo2.denom);
                print("Zeit für Clear: \(elapsedNano2)")
                let t2 = mach_absolute_time()
                var insertcounter = 0
                for attendee in attendees {
                    
                    let is_cancelled = attendee.is_cancelled!
                    
                    switch is_cancelled{
                        
                    case 0:
                        
                        let attendeeRealmObject = Attendee()
                        attendeeRealmObject.ticketId = attendee.ticketid
                        attendeeRealmObject.orderId = attendee.orderid
                        attendeeRealmObject.firstName = attendee.firstname
                        attendeeRealmObject.lastName = attendee.lastname
                        attendeeRealmObject.private_reference_number = attendee.private_reference_number
                        attendeeRealmObject.arrived = false
                        attendeeRealmObject.eventName = self.eventarray[(attendee.eventid)-1]
                        
                        let realm = try! Realm()
                        
                        try! realm.write {
                            realm.add(attendeeRealmObject)
                            //print("Added \(attendeeRealmObject.firstName) to Realm")
                            insertcounter = insertcounter + 1
                        }
                        
                    
                    case 1:
                        break
                        
                    default:
                        break
                        
                    }
                 
                }
                
                
                // do something
                
                
                
                let elapsed = t2 - t1
                var timeBaseInfo = mach_timebase_info_data_t()
                mach_timebase_info(&timeBaseInfo)
                let elapsedNano = elapsed * UInt64(timeBaseInfo.numer) / UInt64(timeBaseInfo.denom);
                print("Importzeit: \(elapsedNano)")
                
                
                
                let alertController = UIAlertController(title: "Synchronisation abgeschlossen!", message: "Es wurden \(insertcounter) Datensätze importiert", preferredStyle: .alert)
                
                
                let destroyAction = UIAlertAction(title: "ok", style: .default) { action in
                    
                    self.attendeesCount.text = "Anzahl der Gäste in der Datenbank: \n \(self.countAttendees())"
                    self.status_rect.backgroundColor = UIColor.green
                    
                }
                
                alertController.addAction(destroyAction)
                self.present(alertController, animated: true) {
                    // ...
                }
            }
        }
    }
    
    
   //Ticketing Methods
   func ticketExists(private_reference_number: Int) -> Bool{
    
        let realm = try! Realm()
    
        let attendees = realm.objects(Attendee.self).filter("private_reference_number = \(private_reference_number)")
    
        if (attendees.count != 0){
            
            return true
        
        }else{
            
            return false
        
        }
    }
    
    func hasArrived(private_reference_number: Int) -> Bool{
        
        let realm = try! Realm()
        
        let attendees = realm.objects(Attendee.self).filter("private_reference_number = \(private_reference_number) AND arrived = true")
        
        if (attendees.count != 0){
        
            return true
        
        } else{
        
            return false
        }
    }
    
    func checkIn(private_reference_number: Int){
        
        let realm = try! Realm()
        
        let attendees = realm.objects(Attendee.self).filter("private_reference_number = \(private_reference_number)")
        
        if(attendees.count > 1){
            print("Error: TicketID not unique!")
        }else if (attendees.count == 0){
            print("Error: Ticket doesn't exist")
        }else{
            let date = NSDate()
            let calendar = NSCalendar.current
            let month = calendar.component(.month, from: date as Date)
            let day = calendar.component(.day, from: date as Date)
            let hour = calendar.component(.hour, from: date as Date)
            let minute = calendar.component(.minute, from: date as Date)
            
            let timestamp: String = ("\(day).\(month) \(hour):\(minute)")
            
            try! realm.write {
                realm.create(Attendee.self, value: ["private_reference_number": private_reference_number, "arrived": true, "checkinTime": timestamp], update: true)
            }
        }
    }
    
    func checkOut(private_reference_number: Int){
        
        let realm = try! Realm()
        
        let attendees = realm.objects(Attendee.self).filter("private_reference_number = \(private_reference_number)")
        
        if(attendees.count > 1){
            print("Error: TicketID not unique!")
        }else if (attendees.count == 0){
            print("Error: Ticket doesn't exist")
        }else{
            try! realm.write {
                realm.create(Attendee.self, value: ["private_reference_number": private_reference_number, "arrived": false], update: true)
            }
        }
    }
    
    func getNameForTicket(private_reference_number: Int) -> String{
        
        var attendeeName = ""
        
        let realm = try! Realm()
        
        let attendees = realm.objects(Attendee.self).filter("private_reference_number = \(private_reference_number)")
        
        if (attendees.count == 1){
            attendeeName = (attendees[0].firstName + " " + attendees[0].lastName)
        }else{
            attendeeName = "Attendeename not found!"
        }
        return attendeeName
    }
    
    func getCheckinTime(private_reference_number: Int) -> String{
        
        var checkinTime = ""
        
        let realm = try! Realm()
        
        let attendees = realm.objects(Attendee.self).filter("private_reference_number = \(private_reference_number)")
        
        if (attendees.count == 1){
            checkinTime = attendees[0].checkinTime
        }else{
            checkinTime = "Not checked in yet"
        }
        return checkinTime
    }
    
    func countAttendees() -> Int{
        
        let realm = try! Realm()
        
        let attendees = realm.objects(Attendee.self)
        
        return attendees.count
    
    }
    
    func countAttendeesArrived() -> Int{
        
        let realm = try! Realm()
        
        let attendeesArrived = realm.objects(Attendee.self).filter("arrived = true")

        return attendeesArrived.count
        
        
    }
    
    func getSyncedEvent() -> String{
        
        let realm = try! Realm()
        
        let attendees = realm.objects(Attendee.self)
        
        return (attendees.first?.eventName)!
    }
}
