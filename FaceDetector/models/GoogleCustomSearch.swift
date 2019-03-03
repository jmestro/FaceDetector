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

// Partial implementation of the Google Custom Search API

struct GoogleCustomSearch: Codable {
	let kind: String
	let url: Url
	let queries: QueriesSet
	let items: [Item]
}

struct Url: Codable {
	let type: String
	let template: String
}

struct QueriesSet: Codable {
	let request: [Query]
	let nextPage: [Query]
}

struct Query: Codable {
	let title: String
	let totalResults: String
	let searchTerms: String
	let count: Int
	let startIndex: Int
	let lowRange: String
	let highRange: String
	let searchType: String
	let imgType: String
}

struct Item: Codable {
	let title: String
	let link: String
	let displayLink: String
	let mime: String
}
