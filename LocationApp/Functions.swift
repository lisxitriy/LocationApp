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

//чтобы найти папку кор даты
//кор дата хранит данные в SQLite db. Файл называется LocationApp.sqlite и  находится в папке библиотеки приложения

let applicationDocumentsDirectory: URL = {
    let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

    return path[0]
    
}()


let dataSaveFailedNotification = Notification.Name("DataSaveFailedNotification")

func fatalCoreDataError(_ error: Error) {
    print("*** Fata error: \(error)")
    NotificationCenter.default.post(name: dataSaveFailedNotification, object: nil)
}
