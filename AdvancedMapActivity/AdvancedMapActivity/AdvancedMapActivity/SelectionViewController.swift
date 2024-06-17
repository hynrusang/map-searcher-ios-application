//
//  ViewController.swift
//  AdvancedMapActivity
//
//  Created by 환류상 on 6/17/24.
//

import UIKit
import MapKit

class SelectionViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var autoCompleteView: UITableView!
    let autoCompleter = MKLocalSearchCompleter()
    var autoCompleteResults: [MKLocalSearchCompletion] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        autoCompleteView.delegate = self
        autoCompleteView.dataSource = self
        autoCompleter.delegate = self
        autoCompleter.resultTypes = .address
    }
}

extension SelectionViewController {
    func searchLocation(_ query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        MKLocalSearch(request: request).start {
            (response, error) in
            guard let response = response, let item = response.mapItems.first else { return }
            let alert = UIAlertController(title: nil, message: "해당 장소가 추가되었습니다", preferredStyle: .alert)
            
            self.pushDataToAppDelegate(item)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
            
            self.searchBar.text = ""
            self.autoCompleteResults.removeAll()
            self.autoCompleteView.reloadData()
            self.present(alert, animated: true, completion: nil)
        }
    }
    func pushDataToAppDelegate(_ mapItem: MKMapItem) {
        let name = mapItem.name ?? ""
        let apikey = "AIzaSyAlIqLmmDMG5ND1Wd9BH5UsG23-zvqW6t0"
        let query = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=\(name)&inputtype=textquery&fields=photos,formatted_address,name,rating,opening_hours,geometry&key=\(apikey)"
        guard let url = URL(string: query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else { return }
        
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            guard let data = data, error == nil else { return }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let photos = candidates.first?["photos"] as? [[String: Any]],
            let photoReference = photos.first?["photo_reference"] as? String {
                self.fetchPlacePhotoThen(reference: photoReference, apikey) {
                    (image) in
                    DispatchQueue.main.async {
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.locations.append((name: name, formatName: candidates.first?["formatted_address"] as? String ?? name, coord: mapItem.placemark.coordinate, image: image))
                    }
                }
            }
        }.resume()
    }
    func fetchPlacePhotoThen(reference: String, _ apikey: String, completion: @escaping (UIImage?) -> Void) {
        let query = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=\(reference)&key=\(apikey)"
        guard let url = URL(string: query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else { return }
        
        URLSession.shared.dataTask(with: url) { 
            (data, response, error) in
            guard let data = data, error == nil,
            let image = UIImage(data: data) else { return }
            
            completion(image)
        }.resume()
    }
}

extension SelectionViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        autoCompleter.queryFragment = searchText
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard let text = searchBar.text, !text.isEmpty else { return }
        searchLocation(text)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        autoCompleteResults.removeAll()
        autoCompleteView.reloadData()
    }
}

extension SelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = autoCompleteResults[indexPath.row]
        searchBar.text = result.title
    }
}

extension SelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autoCompleteResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let label = UILabel()
        let result = autoCompleteResults[indexPath.row]

        label.numberOfLines = 0
        label.text = result.title
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        
        cell.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            label.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            label.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])
        return cell
    }
}

extension SelectionViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        autoCompleteResults = completer.results
        autoCompleteView.reloadData()
    }
}
