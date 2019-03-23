//
//  InterfaceController.swift
//  WorkoutSessionSample WatchKit Extension
//
//  Created by Nobuhiro Takahashi on 2019/03/23.
//  Copyright © 2019 Nobuhiro Takahashi. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {

    var healthStore = HKHealthStore()
    var session: HKWorkoutSession!
    @IBOutlet weak var timer: WKInterfaceTimer!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        let readSet = Set<HKObjectType>(arrayLiteral:
            HKObjectType.workoutType()
        )
        let writeSet = Set<HKSampleType>(arrayLiteral:
            HKSampleType.workoutType()
        )
        healthStore.requestAuthorization(toShare: writeSet, read: readSet) { (success, error) in
            //
        }
    }
    @IBAction func startButtonWasTapped() {
        startIndoorRunning()
        
        timer.setDate(Date())
        timer.start()
    }
    @IBAction func pauseButtonWasTapped() {
        pauseAndResume()
        
    }
    @IBAction func stopButtonWasTapped() {
        stopSession()
        timer.stop()
    }
    
    func startIndoorRunning() {
        print("start")
        let configure = HKWorkoutConfiguration()
        configure.activityType = .running
        configure.locationType = .indoor
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configure)
            session.delegate = self
            session.prepare()
            session.startActivity(with: Date())
        } catch {
            print(error)
        }
    }
    func pauseAndResume() {
        print("pause or resume")
        if session.state == .running {
            session.pause()
            timer.stop()
        } else if session.state == .paused {
            session.resume()
            timer.start()
        }
    }
    func stopSession() {
        print("stop")
        session.stopActivity(with: Date())
        session.end()
        
    }
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        print("change State: \(date): \(printState(fromState.rawValue)) -> \(printState(toState.rawValue))")
        
        if toState.rawValue == HKWorkoutSessionState.ended.rawValue {
            print(session.startDate.debugDescription)
            // ended のステータスに didChanged されてから値が入る
            print(session.endDate?.debugDescription)
            print(session.workoutConfiguration.activityType.rawValue)
            print(session.state.rawValue)
            
        }
        
    }
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didFailWithError error: Error) {
        print(error)
        
    }
    func printState(_ stateValue: Int) -> String {
        switch stateValue {
        case HKWorkoutSessionState.notStarted.rawValue:
            return "notStarted"
        case HKWorkoutSessionState.paused.rawValue:
            return "paused"
        case HKWorkoutSessionState.prepared.rawValue:
            return "prepared"
        case HKWorkoutSessionState.running.rawValue:
            return "running"
        case HKWorkoutSessionState.stopped.rawValue:
            return "stopped"
        case HKWorkoutSessionState.ended.rawValue:
            return "ended"
        default:
            return ""
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
