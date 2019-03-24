//
//  ViewController.swift
//  WorkoutSessionSample
//
//  Created by Nobuhiro Takahashi on 2019/03/23.
//  Copyright © 2019 Nobuhiro Takahashi. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let healthStore = HKHealthStore()
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
            //
        }
    }


}

