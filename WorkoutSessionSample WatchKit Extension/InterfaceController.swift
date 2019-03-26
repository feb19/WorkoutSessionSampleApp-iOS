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
    @IBOutlet weak var stateLabel: WKInterfaceLabel!
    var activeEnergy: HKQuantity!
    var heartRate: HKQuantity!
    var queries: [HKQuery] = NSArray() as! [HKQuery]
    var startDate: Date!
    var activeEnergies: [HKQuantitySample] = NSArray() as! [HKQuantitySample]
    var heartRates: [HKQuantitySample] = NSArray() as! [HKQuantitySample]

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        stateLabel.setText("")
        let readSet = Set<HKObjectType>(arrayLiteral:
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        )
        let writeSet = Set<HKSampleType>(arrayLiteral:
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        )
        healthStore.requestAuthorization(toShare: writeSet, read: readSet) { (success, error) in
        }
        activeEnergy = HKQuantity(unit: HKUnit.smallCalorie(), doubleValue: 0.0)
        heartRate = HKQuantity(unit: HKUnit(from: "count/min"), doubleValue: 0.0)
    }
    func createActiveEnergyQuery(workoutStateDate: Date) -> HKQuery {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let unit = HKUnit.smallCalorie()
        
        let query = HKAnchoredObjectQuery(type: type,
                                          predicate: predicate,
                                          anchor: nil,
                                          limit: 0) { (query, samples, deletedObjects, anchor, error) in
            guard let samples = samples as? [HKQuantitySample] else { return }
            var value = self.activeEnergy.doubleValue(for: unit)
            print(value)
            for sample in samples {
                value += sample.quantity.doubleValue(for: unit)
            }
            self.activeEnergy = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: value)
            self.activeEnergies += samples
        }
        return query
        
    }
    func createHeartRateQuery(workoutStateDate: Date) -> HKQuery {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        let type = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let unit = HKUnit(from: "count/min")
        
        let query = HKAnchoredObjectQuery(type: type,
                                          predicate: predicate,
                                          anchor: nil,
                                          limit: 0) { (query, samples, deletedObjects, anchor, error) in
            guard let samples = samples as? [HKQuantitySample] else { return }
            var value = self.heartRate.doubleValue(for: unit)
            for sample in samples {
                value = sample.quantity.doubleValue(for: unit)
            }
            self.heartRate = HKQuantity(unit: unit, doubleValue: value)
            self.heartRates += samples
            self.queries.append(query)
//            self.healthStore.execute(query)
        }
        return query
        
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
            startDate = Date()
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configure)
            session.delegate = self
            session.prepare()
            session.startActivity(with: startDate)
            
            queries.append(createActiveEnergyQuery(workoutStateDate: startDate))
            queries.append(createHeartRateQuery(workoutStateDate: startDate))
            for query in queries {
                healthStore.execute(query)
            }
            
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
        print("----")
        print("change State: \(date): \(printState(fromState.rawValue)) -> \(printState(toState.rawValue))")
        
        stateLabel.setText(printState(toState.rawValue))
        if toState.rawValue == HKWorkoutSessionState.ended.rawValue {
            print(session.startDate.debugDescription)
            // ended のステータスに didChanged されてから値が入る
            print(session.endDate?.debugDescription ?? "eneded data")
            let activityType = session.workoutConfiguration.activityType
            let duration = session.endDate?.timeIntervalSince(session.startDate ?? Date()) ?? 0
            let start = session.startDate ?? Date()
            let end = session.endDate ?? Date()
            self.queries.removeAll()
            print(activityType.rawValue)
            print(session.state.rawValue)
            print(duration)
            print(start)
            print(end)
            let workout = HKWorkout(activityType: activityType,
                      start: start,
                      end: end,
                      duration: duration,
                      totalEnergyBurned: self.activeEnergy,
                      totalDistance: nil,
                      metadata: nil)
            
            var samples : [HKQuantitySample] = []
            samples += activeEnergies
            samples += heartRates
            healthStore.save(workout, withCompletion: {(success,error) in
                print("save? \(success)")
                if success, samples.count > 0 {
                    self.healthStore.add(samples, to: workout, completion: { (success, error) in
                    
                    })
                }
            })
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
