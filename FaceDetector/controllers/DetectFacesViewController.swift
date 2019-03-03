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

class DetectFacesViewController: UIViewController {

	@IBOutlet weak var celebImage: UIImageView!
	@IBOutlet weak var celebThumbnailImageCollectionView: UICollectionView!
	@IBOutlet weak var facesCollectionView: UICollectionView!
	@IBOutlet weak var selectedPersonLabel: UILabel!
	@IBOutlet weak var batchProgressView: UIProgressView!
	
	private var peopleMang = PeopleManagement.shared
	private var itemMang = ItemManagement.shared
	private var foundFaces: [UIImage] = []
	private var selectedFace: UIImage?
	
	// MARK: - View lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		celebThumbnailImageCollectionView.delegate = self
		celebThumbnailImageCollectionView.dataSource = self
		facesCollectionView.delegate = self
		facesCollectionView.dataSource = self
		facesCollectionView.allowsMultipleSelection = false
		facesCollectionView.allowsSelection = true
		
		celebImage.layer.decorate()
		celebThumbnailImageCollectionView.layer.decorate()
		celebThumbnailImageCollectionView.allowsMultipleSelection = false
		celebThumbnailImageCollectionView.allowsSelection = true
		facesCollectionView.layer.decorate()
		
		selectedPersonLabel.text = "Select a person from the Face Albums tab"
		if let selectedPerson = peopleMang.selectedPerson {
			selectedPersonLabel.text = selectedPerson
			itemMang.getAssets(for: selectedPerson)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		guard let selectedPerson = peopleMang.selectedPerson else { return }
		
		itemMang.trainingItems.removeAll()
		foundFaces.removeAll()
		facesCollectionView.reloadData()
		itemMang.getAssets(for: selectedPerson)
		celebImage.image = nil
		celebThumbnailImageCollectionView.reloadData()
		selectedPersonLabel.text = selectedPerson
		batchProgressView.progress = 0
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		guard let selectedPerson = peopleMang.selectedPerson else { return }
		
		itemMang.persistUrls(for: selectedPerson)
	}
	
	// MARK: - Button methods
	@IBAction func appendSelectedFaceToTraining(_ sender: UIButton) {
		guard let selectedFace = selectedFace,
			let selectedPerson = peopleMang.selectedPerson,
			let selectedThumbnail = celebThumbnailImageCollectionView.indexPathsForSelectedItems?.first
		else { return }
		
		if let faceUrl = itemMang.persistTrainingFace(croppedFaceImage: selectedFace, personName: selectedPerson) {
			itemMang.trainingFaces.append(faceUrl)
			
			itemMang.trainingItems.remove(at: selectedThumbnail.item)
			celebThumbnailImageCollectionView.reloadData()
			foundFaces.removeAll()
			facesCollectionView.reloadData()
			celebImage.image = nil
		}
	}
	
	// TODO: ProgressView cannot refresh in time because of too many progress updates.
	@IBAction func batchAppendFacesToTraining(_ sender: UIButton) {
		guard let selectedPerson = peopleMang.selectedPerson else { return }
		
		var itemsToDelete: [URL] = []
		var faceJob = itemMang.trainingItems
		let progress = Float(faceJob.count)
		
		let group = DispatchGroup()
		group.enter()
		
		DispatchQueue.global(qos: .default).async {
			while !faceJob.isEmpty {
				let url = faceJob.first!
				KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { result in
					switch result {
					case .success(let image):
						
						
						let faces = FoundFace.getCroppedFaces(image: image.image)
						if faces.count == 1 {
							let targetFace = faces.first!.face
							if let faceUrl = self.itemMang.persistTrainingFace(croppedFaceImage: targetFace, personName: selectedPerson) {
								self.itemMang.trainingFaces.append(faceUrl)
								itemsToDelete.append(url)
							}
						}
					case .failure:
						break
					} // switch
				}
				faceJob.remove(at: 0)
				DispatchQueue.main.async {
					self.batchProgressView.progress = progress - Float(faceJob.count) / progress
				}
			} // while
			
			DispatchQueue.main.async {
				group.leave()
			}
		}
		
		group.notify(queue: .main) {
			itemsToDelete.forEach({ url in
				if let index = self.itemMang.trainingItems.firstIndex(of: url) {
					self.itemMang.trainingItems.remove(at: index)
				}
			})
			
			self.celebThumbnailImageCollectionView.reloadData()
			self.foundFaces.removeAll()
			self.facesCollectionView.reloadData()
			self.celebImage.image = nil
		}
	}
	
}

// MARK: - Collection view support
extension DetectFacesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if collectionView == celebThumbnailImageCollectionView {
			return itemMang.trainingItems.count
		} else {
			return foundFaces.count
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if collectionView == celebThumbnailImageCollectionView {
			let cell = celebThumbnailImageCollectionView.dequeueReusableCell(withReuseIdentifier: "TrainingImageCell", for: indexPath) as! FacesCollectionViewCell
			cell.faceImageView.kf.setImage(with: itemMang.trainingItems[indexPath.item], placeholder: UIImage(named: "searching"))
			
			return cell
			
		} else {
			let cell = facesCollectionView.dequeueReusableCell(withReuseIdentifier: "FaceCell", for: indexPath) as! FoundFaceCollectionViewCell
			cell.foundFaceImageView.image = foundFaces[indexPath.item]
			
			return cell
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if collectionView == celebThumbnailImageCollectionView {
			celebImage.kf.setImage(with: itemMang.trainingItems[indexPath.item], placeholder: UIImage(named: "searching"))
			foundFaces = FoundFace.getCroppedFaces(image: celebImage.image!).map({ $0.face })
			facesCollectionView.reloadData()
			if foundFaces.count > 0 {
				facesCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: true, scrollPosition: .top)
				selectedFace = foundFaces.first!
			}
		} else {
			let cell = facesCollectionView.cellForItem(at: indexPath) as! FoundFaceCollectionViewCell
			selectedFace = cell.foundFaceImageView.image
		}
	}
	
}

// MARK: - Table view support
extension DetectFacesViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return foundFaces.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "FoundFaceTableCell") as! FoundFaceTableViewCell
		cell.foundFaceImageView.image = foundFaces[indexPath.row]
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let cell = tableView.cellForRow(at: indexPath) as! FoundFaceTableViewCell
		selectedFace = cell.foundFaceImageView.image
	}

}
