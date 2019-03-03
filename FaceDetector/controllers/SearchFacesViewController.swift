// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
//	regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//		http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import UIKit
import Kingfisher

class SearchFacesViewController: UIViewController {
	
	@IBOutlet weak var selectedNameLabel: UILabel!
	@IBOutlet weak var searchResultsCollectionView: UICollectionView!
	@IBOutlet weak var trainingCollectionView: UICollectionView!
	@IBOutlet weak var verificationCollectionView: UICollectionView!
	@IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var moveSelectedToTrainingButton: UIButton!
	@IBOutlet weak var moveSelectedToVerificationButton: UIButton!
	
	private var peopleMang = PeopleManagement.shared
	private var itemMang = ItemManagement.shared
	
	// MARK: - View lifecycle
	override func viewDidLoad() {
        super.viewDidLoad()

		searchResultsCollectionView.dataSource = self
		searchResultsCollectionView.delegate = self
		trainingCollectionView.dataSource = self
		trainingCollectionView.delegate = self
		verificationCollectionView.dataSource = self
		verificationCollectionView.delegate = self
		searchBar.delegate = self
		
		searchResultsCollectionView.layer.decorate()
		searchResultsCollectionView.allowsMultipleSelection = true
		trainingCollectionView.layer.decorate()
		verificationCollectionView.layer.decorate()
		
		selectedNameLabel.text = "Select a person from the Face Albums tab"
		if let selectedPerson = peopleMang.selectedPerson {
			selectedNameLabel.text = selectedPerson
			itemMang.getAssets(for: selectedPerson)
		}
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		guard let selectedPerson = peopleMang.selectedPerson else { return }
		
		itemMang.getAssets(for: selectedPerson)
		searchResultsCollectionView.reloadData()
		trainingCollectionView.reloadData()
		verificationCollectionView.reloadData()
		selectedNameLabel.text = peopleMang.selectedPerson
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		guard let selectedPerson = peopleMang.selectedPerson else { return }
		
		itemMang.persistUrls(for: selectedPerson)
	}
	
	// MARK: - Button methods
	@IBAction func deselectAllButton(_ sender: UIButton) {
		let selected = searchResultsCollectionView.indexPathsForSelectedItems
		selected?.forEach({ (indexpath) in
			searchResultsCollectionView.deselectItem(at: indexpath, animated: true)
			if let cell = searchResultsCollectionView.cellForItem(at: indexpath) as? SearchResultCollectionViewCell {
				cell.isSelected = false
			}
		})
	}
	
	@IBAction func selectAllButton(_ sender: UIButton) {
		for item in 0 ..< searchResultsCollectionView.numberOfItems(inSection: 0) {
			searchResultsCollectionView.selectItem(at: IndexPath(item: item, section: 0), animated: true, scrollPosition: [])
			if let cell = searchResultsCollectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? SearchResultCollectionViewCell {
				cell.isSelected = true
			}
		}
	}
	
	@IBAction func deleteSelectedButton(_ sender: UIButton) {
		if let selected = searchResultsCollectionView.indexPathsForSelectedItems {
			let itemsToDelete = selected.map { (indexpath) -> URL in
				itemMang.searchPhotoItems[indexpath.item]
			}
			
			itemsToDelete.forEach({
				if let index = itemMang.searchPhotoItems.firstIndex(of: $0) {
					itemMang.searchPhotoItems.remove(at: index)
				}
			})
			searchResultsCollectionView.deleteItems(at: selected)
			peopleMang.persistRequiredFor = peopleMang.selectedPerson
		}
	}
	
	@IBAction func moveSelectedPhotosToTrainingButton(_ sender: UIButton) {
		if let selected = searchResultsCollectionView.indexPathsForSelectedItems {
			var itemsToDelete: [URL] = []
			selected.forEach({ indexpath in
				if sender == moveSelectedToTrainingButton {
					itemMang.trainingItems.append(itemMang.searchPhotoItems[indexpath.item])
				} else {
					itemMang.verificationItems.append(itemMang.searchPhotoItems[indexpath.item])
				}
				itemsToDelete.append(itemMang.searchPhotoItems[indexpath.item])
			})
			
			itemsToDelete.forEach({
				if let index = itemMang.searchPhotoItems.firstIndex(of: $0) {
					itemMang.searchPhotoItems.remove(at: index)
				}
			})
			
			searchResultsCollectionView.deleteItems(at: selected)
			trainingCollectionView.reloadData()
			verificationCollectionView.reloadData()
			peopleMang.persistRequiredFor = peopleMang.selectedPerson
		}
	}
	
}

// MARK: - Collection view support
extension SearchFacesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch collectionView {
		case searchResultsCollectionView:
			return itemMang.searchPhotoItems.count
		case trainingCollectionView:
			return itemMang.trainingItems.count
		case verificationCollectionView:
			return itemMang.verificationItems.count
		default:
			return 0
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if collectionView == searchResultsCollectionView {
			let cell = searchResultsCollectionView.dequeueReusableCell(withReuseIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCollectionViewCell
			cell.searchResultImageView.kf.setImage(with: itemMang.searchPhotoItems[indexPath.item], placeholder: UIImage(named: "searching"))
			cell.isSelected = false
			
			return cell
			
		} else if collectionView == trainingCollectionView {
			let cell = trainingCollectionView.dequeueReusableCell(withReuseIdentifier: "TrainingCell", for: indexPath) as! TrainingCollectionViewCell
			cell.trainingImageView.kf.setImage(with: itemMang.trainingItems[indexPath.item], placeholder: UIImage(named: "searching"))
			
			return cell
			
		} else {
			let cell = verificationCollectionView.dequeueReusableCell(withReuseIdentifier: "VerificationCell", for: indexPath) as! VerificationCollectionViewCell
			cell.verificationImageView.kf.setImage(with: itemMang.verificationItems[indexPath.item], placeholder: UIImage(named: "searching"))
			
			return cell
		}
	}

}

// MARK: - Google Custom Search request
// Uncomment to enable Google Custom Searching
extension SearchFacesViewController: UISearchBarDelegate {
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//		guard let searchPhrase = searchBar.text else { return }
//		guard searchPhrase.trimmingCharacters(in: .whitespaces) != "" else { return }
//
//		searchBar.resignFirstResponder()
//
//		// TODO: Calculate page limit against result count
//		for page in 1 ... 10 {
//			if let request = GoogleService.imageGetRequest(for: searchPhrase, page: page) {
//				DispatchQueue.global(qos: .userInitiated).async {
//
//					URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
//						do {
//							let responseModel = try JSONDecoder().decode(GoogleCustomSearch.self, from: data!)
//							self.gatherSearchItems(items: responseModel.items)
//
//							DispatchQueue.main.async {
//								self.searchResultsCollectionView.reloadData()
//							}
//						} catch let error{
//							print(error)
//						}
//					}).resume()
//				}
//
//			}
//		} // end for loop
	}
	
}
