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

// Note: This service is not used for gathering images. The quality of the return set is poor for
// training purposes, but if you need a search engine for your app or website (via Vapor or Kitura),
// this might be useful. The GoogleCustomSearch structs may need additional properties added to
// support your application needs (https://developers.google.com/custom-search/v1/cse/list).
// See SearchFacesViewController for the GET request.

struct GoogleService {
	static let apiKey = "<<Your Google API Key>>"
	static let customSearchEngineId = "<<Your Custom Search ID>>"
	
	static let scheme = "https"
	static let host = "www.googleapis.com"
	static let requestPath = "/customsearch/v1"
	static let maxPageCount = 10
	
	static func imageGetRequest(for searchTerm: String, page: Int = 1) -> URLRequest? {
		guard page <= maxPageCount else { return nil }
		
		let highIndex = page * 10
		let lowIndex = highIndex - 9
		
		let queryItems: [URLQueryItem] = [
			URLQueryItem(name: "q", value: searchTerm),
			URLQueryItem(name: "lowRange", value: String(lowIndex)),
			URLQueryItem(name: "highRange", value: String(highIndex)),
			URLQueryItem(name: "num", value: "10"),
			URLQueryItem(name: "searchType", value: "image"),
			URLQueryItem(name: "imgType", value: "face"),
//			URLQueryItem(name: "imgType", value: "photo"),
			URLQueryItem(name: "cx", value: self.customSearchEngineId),
			URLQueryItem(name: "key", value: self.apiKey)
		]
		
		var urlComponents = URLComponents()
		urlComponents.scheme = self.scheme
		urlComponents.host = self.host
		urlComponents.path = self.requestPath
		urlComponents.queryItems = queryItems
		
		var request = URLRequest(url: urlComponents.url!)
		request.httpMethod = "GET"
		
		return request
	}
	
}
