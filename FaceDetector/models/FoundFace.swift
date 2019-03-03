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

import Foundation
import UIKit
import Vision

struct PersonConfidence {
	let name: String
	let confidence: Float
}

// Use faceLocation to draw a bounding box around a face. Be careful to adjust your coordinates between
// CGRect and the local space.

struct FoundFace {
	let face: UIImage
	let confidenceSet: [PersonConfidence]
	let faceLocation: CGRect

	init(face: UIImage, confidenceSet: [VNClassificationObservation], faceLocation: CGRect) {
		self.face = face
		self.faceLocation = faceLocation
		self.confidenceSet = confidenceSet.map({
			PersonConfidence.init(name: $0.identifier, confidence: $0.confidence)
		})
	}
	
	public static func getCroppedFaces(image: UIImage?) -> [(face: UIImage, rect: CGRect)] {
		guard let image = image?.cgImage else { return [] }
		
		var detectedFaces: [(UIImage, CGRect)] = []
		do {
			let faceDetectionRequest = VNDetectFaceRectanglesRequest()
			let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])
			try requestHandler.perform([faceDetectionRequest])
			
			if let detectionResults = faceDetectionRequest.results {
				detectionResults.forEach({ faceObservation in
					let foundFace = faceObservation as! VNFaceObservation
					let width = foundFace.boundingBox.width * CGFloat(image.width)
					let height = foundFace.boundingBox.height * CGFloat(image.height)
					let x = foundFace.boundingBox.origin.x * CGFloat(image.width)
					let y = (1 - foundFace.boundingBox.origin.y) * CGFloat(image.height) - height
					
					let croppingRect = CGRect(x: x, y: y, width: width, height: height)
					let faceImage = image.cropping(to: croppingRect)
					detectedFaces.append((UIImage(cgImage: faceImage!), croppingRect))
				})
			}
		} catch let error {
			print(error)
		}
		
		return detectedFaces
	}
	
}
