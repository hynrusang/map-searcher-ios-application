//
//  DetailsViewController.swift
//  AdvancedMapActivity
//
//  Created by 환류상 on 6/17/24.
//
import MapKit
import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!.withRenderingMode(.alwaysOriginal)
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

class DetailsViewController: UIViewController {
    @IBOutlet weak var mapListView: UIPickerView!
    @IBOutlet weak var descriptionLabel: UILabel!
    var locations: [(name: String, formatName: String, coord: CLLocationCoordinate2D, image: UIImage?)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapListView.delegate = self
        mapListView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        locations = appDelegate.locations
        mapListView.reloadAllComponents()
        descriptionLabel.text = !locations.isEmpty ? detailInfo(0) : ""
    }
}

extension DetailsViewController {
    func detailInfo(_ row: Int) -> String {
        return "장소명: \(locations[row].formatName)\n좌표: \(locations[row].coord.latitude), \(locations[row].coord.longitude)"
    }
}

extension DetailsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        let imageView = UIImageView(image: locations[row].image?.resized(to: CGSize(width: 800, height: 400)))
        
        label.text = locations[row].name
        label.textAlignment = .center
        imageView.contentMode = .scaleAspectFit
        
        let stackView = UIStackView(arrangedSubviews: [imageView, label])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 5
        
        return stackView
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        descriptionLabel.text = detailInfo(row)
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.height / 2
    }
}

extension DetailsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return locations.count
    }
}
