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

class FaceAlbumViewController: UIViewController {

	@IBOutlet weak var existingAlbumPickerView: UIPickerView!
	@IBOutlet weak var facesCollectionView: UICollectionView!
	
	private var peopleMang = PeopleManagement.shared
	private var itemMang = ItemManagement.shared
	
	// MARK: - View lifecycle
	override func viewDidLoad() {
        super.viewDidLoad()
		
		existingAlbumPickerView.delegate = self
		existingAlbumPickerView.dataSource = self
		facesCollectionView.delegate = self
		facesCollectionView.dataSource = self
		
		facesCollectionView.layer.decorate()
		
		if let firstPerson = peopleMang.people?.keys.first {
			peopleMang.selectedPerson = firstPerson
			itemMang.getAssets(for: peopleMang.selectedPerson!)
			facesCollectionView.reloadData()
		}
    }
	
	override func viewDidAppear(_ animated: Bool) {
		guard let selectedPerson = peopleMang.people?.keys.first else { return }
		
		peopleMang.selectedPerson = selectedPerson
		itemMang.getAssets(for: selectedPerson)
		facesCollectionView.reloadData()
	}
	
	// MARK: - Button methods
	@IBAction func createPerson(_ sender: UIButton) {
		let alertController = UIAlertController(title: "New Person", message: "Enter a name for the person.", preferredStyle: .alert)
		alertController.addTextField { (textField) in
			textField.placeholder = "Name"
		}
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
			guard let name = alertController.textFields?.first?.text else { return }
			
			self.peopleMang.createPerson(name: name)
			self.existingAlbumPickerView.reloadAllComponents()
			self.itemMang.getAssets(for: name)
			self.facesCollectionView.reloadData()
		}))
		
		self.present(alertController, animated: true)
	}
	
	@IBAction func addToTrainingButton(_ sender: UIButton) {
		guard let personUrls = peopleMang.people?[peopleMang.selectedPerson!] else { return }
		
		let facesCopied = itemMang.copyTrainingFacesToTrainingSet(personUrls: personUrls)
		let message = "\(facesCopied.trainingFaces) training faces and \(facesCopied.testFaces) test faces for \(peopleMang.selectedPerson!) copied into the Training Set folder."
		
		let alert = UIAlertController(title: "Copy Faces", message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		present(alert, animated: true, completion: nil)
	}
}

// MARK: - Picker view support
extension FaceAlbumViewController: UIPickerViewDelegate, UIPickerViewDataSource {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		guard let peopleCount = peopleMang.people?.count else { return 0 }
		
		return peopleCount
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		guard let people = peopleMang.people?.keys else { return nil }
		
		let peopleArray = Array(people)
		return peopleArray[row]
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		guard let people = peopleMang.people?.keys else { return }
		
		let peopleArray = Array(people)
		let selectedPerson = peopleArray[row]
		peopleMang.selectedPerson = selectedPerson
		itemMang.getAssets(for: selectedPerson)
		facesCollectionView.reloadData()
	}
	
}

// MARK: - Collection view support
extension FaceAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return itemMang.trainingFaces.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = facesCollectionView.dequeueReusableCell(withReuseIdentifier: "AlbumFaceCell", for: indexPath) as! AlbumCollectionViewCell
		cell.albumFaceImageView.image = UIImage(contentsOfFile: itemMang.trainingFaces[indexPath.item].path)
		
		return cell
	}
	
}
