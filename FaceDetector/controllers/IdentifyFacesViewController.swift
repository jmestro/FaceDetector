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
import Vision

class IdentifyFacesViewController: UIViewController {

	@IBOutlet weak var photo: UIImageView!
	@IBOutlet weak var confidenceTableView: UITableView!
	@IBOutlet weak var verificationPhotosCollectionView: UICollectionView!

	fileprivate var peopleMang = PeopleManagement.shared
	fileprivate var itemMang = ItemManagement.shared
	
	fileprivate var celebrityPhotos: [URL]?
	fileprivate var recognizedFaces: [FoundFace] = []
	fileprivate var confidenceSet: [VNClassificationObservation] = []
	
	// MARK: - View lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		confidenceTableView.delegate = self
		confidenceTableView.dataSource = self
		verificationPhotosCollectionView.delegate = self
		verificationPhotosCollectionView.dataSource = self
		
		photo.layer.decorate()
		confidenceTableView.layer.decorate()
		verificationPhotosCollectionView.layer.decorate()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		photo.image = nil
		recognizedFaces.removeAll()
		confidenceTableView.reloadData()
		verificationPhotosCollectionView.reloadData()
	}
	
	// MARK: - Image classification request
	fileprivate lazy var classificationRequest: VNCoreMLRequest = {
		do {
			let model = try VNCoreMLModel(for: CelebrityFaces().model)
			
			let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
				self?.processClassifications(for: request, error: error)
			})
			request.imageCropAndScaleOption = .centerCrop
			
			return request
		} catch let error {
			fatalError(error.localizedDescription)
		}
	}()
	
	func processClassifications(for request: VNRequest, error: Error?) {
		DispatchQueue.main.async {
			guard let results = request.results else { return }
			
			let classifications = results as! [VNClassificationObservation]
			if !classifications.isEmpty {
				self.confidenceSet = classifications
			}
		}
	}

	func findPeople() {
		let faces = FoundFace.getCroppedFaces(image: photo.image)
		
		recognizedFaces.removeAll()
		
		for face in faces {
			let orientation = CGImagePropertyOrientation(face.face.imageOrientation)
			guard let ciImage = CIImage(image: face.face) else { continue }
			
			DispatchQueue.global(qos: .userInitiated).async {
				let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
				do {
					self.confidenceSet.removeAll()
					try handler.perform([self.classificationRequest])
					DispatchQueue.main.async {
						self.recognizedFaces.append(FoundFace.init(face: face.face, confidenceSet: self.confidenceSet, faceLocation: face.rect))
						self.confidenceTableView.reloadData()
					}
					
				} catch let error {
					print(error.localizedDescription)
				}
			} // end dispatch
		}
		self.confidenceTableView.reloadData()
	}
	
}

// MARK: - Collection view support
extension IdentifyFacesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return itemMang.verificationItems.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ModelVerificationCell", for: indexPath) as! ModelVerificationCollectionViewCell
		cell.modelVerificationImageView.kf.setImage(with: itemMang.verificationItems[indexPath.item], placeholder: UIImage(named: "searching"))
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		photo.kf.setImage(with: itemMang.verificationItems[indexPath.item], placeholder: UIImage(named: "searching"))
		findPeople()
	}
	
}

// MARK: Table view support
extension IdentifyFacesViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return recognizedFaces.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "FaceCell") as! FaceTableViewCell
		cell.update(withFace: recognizedFaces[indexPath.row])
		
		return cell
	}
	
}
