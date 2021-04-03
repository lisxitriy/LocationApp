//
//  Functions.swift
//  LocationApp
//
//  Created by Olga Trofimova on 03.04.2021.
//

import Foundation

func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: run)
}
