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
            HKObjectType.workoutType()
        )
        let writeSet = Set<HKSampleType>(arrayLiteral:
            HKSampleType.workoutType()
        )
        healthStore.requestAuthorization(toShare: writeSet, read: readSet) { (success, error) in
            //
        }
    }


}

