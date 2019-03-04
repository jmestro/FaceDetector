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

final class ItemManagement {
	private var fileMang = FileManager.default
	private let peopleMang = PeopleManagement.shared
	public static let shared = ItemManagement()
	
	var searchPhotoItems: [URL] = []
	var trainingItems: [URL] = []
	var verificationItems: [URL] = []
	var trainingFaces: [URL] = []
	var testFaces: [URL] = []
	
	private init() { }
	
	init(personName: String) {
		getAssets(for: personName)
	}
	
	// Brute force method for collecting URLs.
	// The persons name is that same as the root directory for all of the URLs and .png files.
	public func getAssets(for person: String) {
		guard let personUrls = peopleMang.people?[person] else { return }
		
		if let persistPerson = peopleMang.persistRequiredFor {
			persistUrls(for: persistPerson)
			peopleMang.persistRequiredFor = nil
		}
		
		clearAllItems()
		searchPhotoItems.append(contentsOf: gatherUrls(from: personUrls.faceCandidatesUrl, optionalPrefix: "Image URL: "))
		searchPhotoItems.append(contentsOf: gatherUrls(from: personUrls.faceCandidatesPendingReview))
		trainingItems.append(contentsOf: gatherUrls(from: personUrls.faceCandidatesAssignmentsUrl))
		verificationItems.append(contentsOf: gatherUrls(from: peopleMang.verficationUrl!))
		trainingFaces.append(contentsOf: gatherFaces(from: personUrls.trainingFaces))
		testFaces.append(contentsOf: gatherFaces(from: personUrls.testFaces))
	}

	public func persistUrls(for person: String) {
		guard let personUrls = peopleMang.people?[person] else { return }
		
		persistOrphanUrls(personUrls: personUrls)
		persistTrainingUrls(personUrls: personUrls)
		persistVerificationUrls(personUrls: personUrls)
		peopleMang.persistRequiredFor = nil
	}
	
	fileprivate func gatherUrls(from url: URL, optionalPrefix prefix: String? = nil) -> [URL] {
		var urls: [URL] = []
		
		do {
			let dirContents = try fileMang.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
			let files = dirContents.filter({ !$0.hasDirectoryPath })
			files.forEach({ file in
				let fileUrls = gatherPhotoUrls(from: file, withOptionalPrefix: prefix)
				urls.append(contentsOf: fileUrls)
			})
		} catch let error {
			fatalError(error.localizedDescription)
		}
		
		return urls
	}
	
	fileprivate func gatherFaces(from url: URL) -> [URL] {
		var urls: [URL] = []
		
		do {
			let dirContents = try fileMang.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])
			urls = dirContents.filter({ !$0.hasDirectoryPath })
		} catch let error {
			fatalError(error.localizedDescription)
		}
		
		return urls
	}
	
	// Do the actual work of retrieving URLs from a file
	fileprivate func gatherPhotoUrls(from url: URL, withOptionalPrefix prefix: String? = nil) -> [URL] {
		var photoUrls: [URL] = []
		
		do {
			let fileContent = try String(contentsOf: url)
			var fileLines = fileContent.components(separatedBy: .newlines)
			if let prefix = prefix {
				fileLines = fileContent.components(separatedBy: .newlines).filter({ $0.hasPrefix(prefix) })
			}
			
			for line in fileLines {
				let extractedUrl = line.replacingOccurrences(of: prefix ?? "", with: "")
				if !extractedUrl.isEmpty {
					if let url = URL(string: extractedUrl) {
						photoUrls.append(url)
					}
				}
			}
		} catch let error {
			print(error)
		}
		
		return photoUrls
	}
	
	fileprivate func clearAllItems() {
		if let persistPerson = peopleMang.persistRequiredFor {
			persistUrls(for: persistPerson)
			peopleMang.persistRequiredFor = nil
		}
		
		searchPhotoItems = []
		trainingItems = []
		verificationItems = []
		trainingFaces = []
		testFaces = []
	}
	
	// Save all of the unassigned and undeleted photo URLs for later review
	fileprivate func persistOrphanUrls(personUrls: PersonUrls) {
		do {
			if searchPhotoItems.count > 0 {
				let orphans = searchPhotoItems.map({ $0.absoluteString }).joined(separator: "\n")
				let orphanArchivePath = personUrls.faceCandidatesPendingReview.appendingPathComponent("orphanPhotos").appendingPathExtension("txt")
				try? fileMang.removeItem(at: orphanArchivePath)
				try orphans.write(to: orphanArchivePath, atomically: true, encoding: .utf8)
			}
		} catch let error {
			print(error)
		}
	}
	
	// Save all photo URLs assigned to training
	fileprivate func persistTrainingUrls(personUrls: PersonUrls) {
		do {
			let training = trainingItems.map({ $0.absoluteString }).joined(separator: "\n")
			let trainingPath = personUrls.faceCandidatesAssignmentsUrl.appendingPathComponent("trainingPhotos").appendingPathExtension("txt")
			try? fileMang.removeItem(at: trainingPath)
			try training.write(to: trainingPath, atomically: true, encoding: .utf8)
		} catch let error {
			print(error)
		}
	}
	
	// Save verification photo URLs to the shared Verification folder
	fileprivate func persistVerificationUrls(personUrls: PersonUrls) {
		do {
			let verification = verificationItems.map({ $0.absoluteString }).joined(separator: "\n")
			let verificationPath = peopleMang.verficationUrl!.appendingPathComponent("verificationPhotos").appendingPathExtension("txt")
			try? fileMang.removeItem(at: verificationPath)
			try verification.write(to: verificationPath, atomically: true, encoding: .utf8)
			
			// Moves your search results into the Archive folder for posterity.
			// You can delete files from this folder and it will not affect image training.
			let contents = try fileMang.contentsOfDirectory(at: personUrls.faceCandidatesUrl, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])
			for file in contents.filter({ !$0.hasDirectoryPath }) {
				let archiveFileName = personUrls.faceCandidatesArchive.appendingPathComponent(FileHelpers.fileNameTimeStamp()).appendingPathExtension("txt")
				try fileMang.moveItem(atPath: file.path, toPath: archiveFileName.path)
			}
		} catch let error {
			print(error)
		}
	}
	
	// Save a training face as a .png file
	@discardableResult fileprivate func persistTrainingFace(croppedFaceImage: UIImage, personUrls: PersonUrls) -> URL? {
		do {
			let trainingFacePath = personUrls.trainingFaces.appendingPathComponent(FileHelpers.fileNameTimeStamp()).appendingPathExtension("png").path
			let faceFile = URL(fileURLWithPath: trainingFacePath)
			try croppedFaceImage.pngData()?.write(to: faceFile)
			
			return faceFile
		} catch let error {
			print(error)
		}
		
		return nil
	}
	
	public func persistTrainingFace(croppedFaceImage: UIImage, personName: String) -> URL? {
		guard let personUrls = peopleMang.people?[personName] else { return nil }
		
		return persistTrainingFace(croppedFaceImage: croppedFaceImage, personUrls: personUrls)
	}
	
	public func copyTrainingFacesToTrainingSet(personUrls: PersonUrls) -> (trainingFaces: Int, testFaces: Int) {
		guard let selectedPerson = peopleMang.selectedPerson else { return (0, 0) }
		
		var trainingFacesCopied = 0
		var testFacesCopied = 0
		
		do {
			let trainingSetUrl = peopleMang.trainingSetUrl!.appendingPathComponent(selectedPerson, isDirectory: true)
			try? fileMang.removeItem(at: trainingSetUrl)
			try fileMang.createDirectory(at: trainingSetUrl, withIntermediateDirectories: true, attributes: nil)
			
			let testSetUrl = peopleMang.testSetUrl!.appendingPathComponent(selectedPerson, isDirectory: true)
			try? fileMang.removeItem(at: testSetUrl)
			try fileMang.createDirectory(at: testSetUrl, withIntermediateDirectories: true, attributes: nil)
			
			let dirContents = try fileMang.contentsOfDirectory(at: personUrls.trainingFaces, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])
			let trainingFaces = dirContents.filter({ !$0.hasDirectoryPath })
			
			let testFaces = trainingFaces[swapRandomlyFor: Int(Double(trainingFaces.count) * 0.2)]
			
			try trainingFaces.forEach({ try fileMang.copyItem(at: $0, to: trainingSetUrl.appendingPathComponent($0.lastPathComponent)) })
			try testFaces.forEach({ try fileMang.copyItem(at: $0, to: testSetUrl.appendingPathComponent($0.lastPathComponent)) })
			
			trainingFacesCopied = trainingFaces.count
			testFacesCopied = testFaces.count
			
		} catch let error {
			print(error)
		}
		
		return (trainingFacesCopied, testFacesCopied)
	}
	
}
