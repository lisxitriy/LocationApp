//
//  LocationDetailsViewController.swift
//  LocationApp
//
//  Created by Olga Trofimova on 30.03.2021.
//

import UIKit
import CoreLocation
import CoreData

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

class LocationDetailsViewController: UITableViewController {
    
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var adressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    var categoryName = "No Category"
    var managedObjectContext: NSManagedObjectContext!
    var image: UIImage?
    var date = Date()
    var observer: Any!
    
    var locationToEdit: Location? {
//        код в этом блоке выполняется всякий раз, когда мы вводим новое значение в эту переменную
        didSet {
            if let location = locationToEdit {
                descriptionText = location.locationDescription
                categoryName = location.category
                date = location.date
                coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                placemark = location.placemark
            }
        }
    }
    var descriptionText = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let location = locationToEdit {
            title = "Edit Location"
            
            if location.hasPhoto {
                if let theImage = location.photoImage {
                    show(image: theImage)
                }
            }
        }
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        if let placemark = placemark {
            adressLabel.text = string(from: placemark)
        } else {
            adressLabel.text = "No Address Found"
        }
        
        dateLabel.text = format(date: date)
        
//        скрываем клавиатуру
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
        
        listenForBackgroundNotification()
    }
    
    @objc func hideKeyboard(_ gestureRecognizer: UIGestureRecognizer) {
        let point = gestureRecognizer.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        if let indexPath = indexPath {
          if  indexPath.section != 0 && indexPath.row != 0 {
            descriptionTextView.resignFirstResponder()
          }
        } else {
            descriptionTextView.resignFirstResponder()
        }
        
       
    }
    //MARK: - Actions
    @IBAction func done() {
//        navigationController?.popViewController(animated: true)
        guard let mainView = navigationController?.parent?.view else { return }
        let hudView = HudView.hud(inView: mainView, animated: true)
        hudView.text = "Tagged"
        
        let location: Location
        
        if let temp = locationToEdit {
            hudView.text = "Updated"
            location = temp
        } else {
            hudView.text = "Tagged"
            location = Location(context: managedObjectContext)
            location.photoID = nil
        }
        
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
        
//        Сохраняем изображения
        
        if let image = image {
            
//  нам нужно получить новый идентификатор и назначить его свойству photoID для Location, если фотографии еще не было. Если фотография существует, сохраняем тот же идентификатор и перезаписываем существующий файл JPEG
            if !location.hasPhoto {
                location.photoID = Location.nextPhotoID() as NSNumber
            }
//  преобразуем UIImage в формат JPEG и возвращаем объект Data
            if let data = image.jpegData(compressionQuality: 0.5) {
//  пытаемся записать данные
                do {
                    try data.write(to: location.photoURL, options: .atomic)
                } catch {
                    print("Error writing file: \(error)")
                }
            }
        }
        
        do {
            try managedObjectContext.save()
            //         чтобы закрыть экран через 6 секунд
            afterDelay(0.6) {
                hudView.hide()
                self.navigationController?.popViewController(animated: true)
            }
        } catch {
            fatalCoreDataError(error)
        }

    }
    
    @IBAction func cancel() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func categoryPickerDidPickCategory(_ segue: UIStoryboardSegue) {
        let controller = segue.source as! CategoryPickerViewController
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    
    // MARK: - Helper Methods
    func string(from placemark: CLPlacemark) -> String {
      var text = ""
      if let tmp = placemark.subThoroughfare {
        text += tmp + " "
      }
      if let tmp = placemark.thoroughfare {
        text += tmp + ", "
      }
      if let tmp = placemark.locality {
        text += tmp + ", "
      }
      if let tmp = placemark.administrativeArea {
        text += tmp + " "
      }
        
     if let tmp = placemark.postalCode {
        text += tmp + ", "
    }
    if let tmp = placemark.country {
        text += tmp
    }
          return text
        }

    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    func show(image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
        addPhotoLabel.text = ""
        
        imageHeight.constant = 260
        tableView.reloadData()
    }
    
//    Когда приложение переходит в фоновый режим, оно должно закрывать лист действий, если он отображается в данный момент.то же самое для средства выбора изображений
    func listenForBackgroundNotification() {
        observer = NotificationCenter.default.addObserver(forName: UIScene.didEnterBackgroundNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            if let weakSelf = self {
                if weakSelf.presentedViewController != nil {
                    weakSelf.dismiss(animated: false, completion: nil)
                }
                    weakSelf.descriptionTextView.resignFirstResponder()
            }
        }
    }
    
//    начиная с iOS 9.0 и выше, если явно не удалять наблюдателя, система обработает это самостоятельно и автоматически удалит наблюдателя, когда контроллер представления будет освобожден. но просто для тренировки и наглядности это здесь есть)
    
    deinit {
      print("*** deinit \(self)")
      NotificationCenter.default.removeObserver(observer!)
    }

    //MARK: - Table View Delegates
    
//    ограничиваем нажатие на ячейки только первыми двумя ячейками
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.row == 0 || indexPath.row == 1 {
            return indexPath
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
//        если пользователь коснется первой строки первого раздела - строки с description text view  - тогда передаем фокус ввода text view
        if indexPath.section == 0 && indexPath.row == 0 {
            descriptionTextView.becomeFirstResponder()
        } else if indexPath.section == 1 && indexPath.row == 0 {
//            takePhotoWithCamera()
//            choosePhotoFromLibrary()
            pickPhoto()
        }
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickCategory" {
            let controller = segue.destination as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }


}


extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: - Image Helper Methods
    
    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let actCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(actCancel)
        
        let actPhoto = UIAlertAction(title: "Take Photo", style: .default) { _ in
            self.takePhotoWithCamera()
        }
        alert.addAction(actPhoto)
        
        let actLibrary = UIAlertAction(title: "Choose From Lobrary", style: .default) { _ in
            self.choosePhotoFromLibrary()
        }
        alert.addAction(actLibrary)
        
        present(alert, animated: true, completion: nil)
    }
    //MARK: - Image Picker Delegates
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //можно переписать через didSet
        image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        if let theImage = image {
            show(image: theImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    

}
