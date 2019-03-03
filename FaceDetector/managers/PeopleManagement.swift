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

final class PeopleManagement {
	
	// These become directory labels
	private let fileMang = FileManager.default
	private let verficationUrlName = "Verification Photos"
	private let trainingSetName = "Training Set"
	private let testSetName = "Test Set"
	private let trainingFacesUrlName = "TrainingFaces"
	private let testFacesUrlName = "TestFaces"
	private let faceCandidateFilesUrlName = "FaceCandidateFiles"
	private let faceCandidateAssignmentsName = "FaceCandidateAssignments"
	private let faceCandidatesPendingReviewName = "PendingReview"
	private let faceCandidatesArchiveName = "Archive"
	
	public static let shared = PeopleManagement()
	private(set) var docUrl: URL?
	public var verficationUrl: URL?
	public var trainingSetUrl: URL?
	public var testSetUrl: URL?
	public var people: [String: PersonUrls]? = [:]
	public var selectedPerson: String?
	public var persistRequiredFor: String?
	
	private init() {
		guard let docDir = fileMang.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
		docUrl = docDir

		createSharedDirectories()
		getPersons()
		
		verficationUrl = docUrl!.appendingPathComponent(verficationUrlName, isDirectory: true)
		trainingSetUrl = docUrl!.appendingPathComponent(trainingSetName, isDirectory: true)
		testSetUrl = docUrl!.appendingPathComponent(testSetName, isDirectory: true)
		
		// For users that wish to run using a simular, use this path from the console output
		// to point to the application document directory.
		print("Root URL located at: ", docUrl!.path)
	}
	
	public func createPerson(name: String) {
		buildPersonDirectories(for: name)
		getPersons()
	}
	
	fileprivate func buildPersonDirectories(for name: String) {
		guard !(self.people?.contains(where: { $0.key == name }))! else { return }
		
		do {
			try fileMang.createDirectory(at: docUrl!.appendingPathComponent(name),
										 withIntermediateDirectories: true,
										 attributes: nil)
			try fileMang.createDirectory(at: docUrl!.appendingPathComponent(name)
				.appendingPathComponent(trainingFacesUrlName),
										 withIntermediateDirectories: true,
										 attributes: nil)
			try fileMang.createDirectory(at: docUrl!.appendingPathComponent(name)
				.appendingPathComponent(testFacesUrlName),
										 withIntermediateDirectories: true,
										 attributes: nil)
			try fileMang.createDirectory(at: docUrl!.appendingPathComponent(name)
				.appendingPathComponent(faceCandidateFilesUrlName),
										 withIntermediateDirectories: true,
										 attributes: nil)
			try fileMang.createDirectory(at: docUrl!.appendingPathComponent(name)
				.appendingPathComponent(faceCandidateFilesUrlName).appendingPathComponent(faceCandidatesPendingReviewName),
										 withIntermediateDirectories: true,
										 attributes: nil)
			try fileMang.createDirectory(at: docUrl!.appendingPathComponent(name)
				.appendingPathComponent(faceCandidateFilesUrlName).appendingPathComponent(faceCandidatesArchiveName),
										 withIntermediateDirectories: true,
										 attributes: nil)
			try fileMang.createDirectory(at: docUrl!.appendingPathComponent(name)
				.appendingPathComponent(faceCandidateFilesUrlName).appendingPathComponent(faceCandidateAssignmentsName),
										 withIntermediateDirectories: true,
										 attributes: nil)
		} catch let error {
			fatalError(error.localizedDescription)
		}
	}
	
	// Root directories represent the name of the person
	fileprivate func getPersons() {
		let excludeUrls = [
			verficationUrlName,
			trainingSetName,
			testSetName]
		
		do {
			let dirItems = try fileMang.contentsOfDirectory(at: docUrl!,
															includingPropertiesForKeys: [],
															options: [FileManager.DirectoryEnumerationOptions.skipsHiddenFiles])
				.filter({ !excludeUrls.contains($0.lastPathComponent) })
				.map { url -> PersonUrls in
					let faceCadidatesUrl = url.appendingPathComponent(faceCandidateFilesUrlName)
					let faceCandidatesAssignmentsUrl = faceCadidatesUrl.appendingPathComponent(faceCandidateAssignmentsName)
					let faceCandidatesPendingReviewUrl = faceCadidatesUrl.appendingPathComponent(faceCandidatesPendingReviewName)
					let faceCandidatesArchiveUrl = faceCadidatesUrl.appendingPathComponent(faceCandidatesArchiveName)
					let testFacesUrl = url.appendingPathComponent(testFacesUrlName)
					let trainingFacesUrl = url.appendingPathComponent(trainingFacesUrlName)
					
					let personUrls = PersonUrls(rootUrl: url,
												faceCandidatesUrl: faceCadidatesUrl,
												faceCandidatesAssignmentsUrl: faceCandidatesAssignmentsUrl,
												faceCandidatesPendingReview: faceCandidatesPendingReviewUrl,
												faceCandidatesArchive: faceCandidatesArchiveUrl,
												testFaces: testFacesUrl,
												trainingFaces: trainingFacesUrl)
				
					return personUrls
				}
			
			dirItems.forEach { personUrls in
				people?[personUrls.rootUrl.lastPathComponent] = personUrls
			}
	
		} catch let error {
			fatalError(error.localizedDescription)
		}
	}
	
	// These directories contain files of all people used to training, testing and verification
	fileprivate func createSharedDirectories() {
		if !fileMang.fileExists(atPath: docUrl!.appendingPathComponent(verficationUrlName, isDirectory: true).path) {
			do {
				try fileMang.createDirectory(at: docUrl!.appendingPathComponent(verficationUrlName, isDirectory: true),
											 withIntermediateDirectories: true,
											 attributes: nil)
			} catch let error {
				fatalError(error.localizedDescription)
			}
		}
		
		if !fileMang.fileExists(atPath: docUrl!.appendingPathComponent(trainingSetName, isDirectory: true).path) {
			do {
				try fileMang.createDirectory(at: docUrl!.appendingPathComponent(trainingSetName, isDirectory: true),
											 withIntermediateDirectories: true,
											 attributes: nil)
			} catch let error {
				fatalError(error.localizedDescription)
			}
		}
		
		if !fileMang.fileExists(atPath: docUrl!.appendingPathComponent(testSetName, isDirectory: true).path) {
			do {
				try fileMang.createDirectory(at: docUrl!.appendingPathComponent(testSetName, isDirectory: true),
											 withIntermediateDirectories: true,
											 attributes: nil)
			} catch let error {
				fatalError(error.localizedDescription)
			}
		}
	}
	
}
