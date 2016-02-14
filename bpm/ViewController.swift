//
//  ViewController.swift
//  bpm
//
//  Created by Zaid Kokaja on 2/13/16.
//  Copyright © 2016 Zaid Kokaja. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    // UI Components
    @IBOutlet var labelView: UILabel!
    @IBOutlet var tapView: UIView!
    let tapRec = UITapGestureRecognizer()
    
    // Class variables
    var healthStore: HKHealthStore? = nil
    var startTime: NSTimeInterval? = nil
    var bpm = 0.0
    var numTaps = 0.0
    let bpmType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
    
    // Initiate view and tap recognizer
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tapRec.addTarget(self, action: "tappedView")
        tapView.addGestureRecognizer(tapRec)
        tapView.userInteractionEnabled = true
        
        if isHealthAvailable() {
            healthStore = HKHealthStore()
            
            if !isHealthAuthorized() {
                requestAuthorization()
            }
        }
        else {
            alertError("Your device does not support HealthKit.")
        }
        
    }
    
    // Handle a tap
    func tappedView() {
        
        if let start = startTime {
            numTaps++
            
            let now = NSDate().timeIntervalSince1970
            let elapsed = now-start
            bpm = (60/elapsed) * numTaps
            
            if numTaps == 15 {
                
                let msg = "Your heart rate is: " + String(Int(bpm))
                
                let tapAlert = UIAlertController(title: "Done!", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                tapAlert.addAction(UIAlertAction(title: "Add to Health", style: .Destructive, handler: addToHomeKit))
                tapAlert.addAction(UIAlertAction(title: "Tap again", style: .Destructive, handler: reset))
                
                self.presentViewController(tapAlert, animated: true, completion: nil)
            }
            
            labelView.text = "Keep Tapping!"
        }
        else {
            startTime = NSDate().timeIntervalSince1970
        }
        
    }
    
    // Add data point to home kit
    func addToHomeKit(alert: UIAlertAction!) {

        if isHealthAvailable() && isHealthAuthorized() {
            let bpmQuantity = HKQuantity(unit: HKUnit(fromString: "count/min"), doubleValue: bpm)
            let bpmSample = HKQuantitySample(type: bpmType!, quantity: bpmQuantity, startDate: NSDate(), endDate: NSDate())
            
            healthStore!.saveObject(bpmSample, withCompletion: { (success, error) -> Void in
                if let err = error {
                    NSLog("Error saving BMI sample: \(err.localizedDescription)")
                }
            })
        }
        else {
            alertError("You must authorize this app to write to Health")
        }
        
        reset(nil)
    }
    
    // Check if health is available on this device
    func isHealthAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // Check if this app is authorized to write the necessary data to Health
    func isHealthAuthorized() -> Bool {
        return healthStore!.authorizationStatusForType(bpmType!) == HKAuthorizationStatus.SharingAuthorized
    }
    
    // Request authorization from the user
    func requestAuthorization() {
        let bpmTypes : Set<HKSampleType> = [bpmType!]
        
        healthStore!.requestAuthorizationToShareTypes(bpmTypes, readTypes: [],
            completion: { (success, error) -> Void in
            if let err = error {
                NSLog("Error requesting for access \(err.localizedDescription)")
            }
        })
    }
    
    // Convenience method for alerting messages to the user
    func alertError(msg: String) {
        let tapAlert = UIAlertController(title: "Alert!", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
        tapAlert.addAction(UIAlertAction(title: "Ok", style: .Destructive, handler: reset))
        
        self.presentViewController(tapAlert, animated: true, completion: nil)
    }
    
    // Reset variables
    func reset(alert: UIAlertAction!) {
        numTaps = 0.0
        startTime = nil
        labelView.text = "Start Tapping!"
    }

    // Default memory warning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Hide the status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

}
