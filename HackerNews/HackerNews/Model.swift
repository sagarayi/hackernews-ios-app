//
//  Model.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/15/25.
//

/**
 // sample Story response
 {
   "by": "dhouston",
   "descendants": 71,
   "id": 8863,
   "kids": [ 8952, 9224 ],
   "score": 111,
   "time": 1175714200,
   "title": "My YC app: Dropbox - Throw away your USB drive",
   "type": "story",
   "url": "http://www.getdropbox.com/u/2/screencast.html"
 }
 */

struct Story: Identifiable, Codable {
    let id: Int
    let by: String?
    let descendants: Int?
    let kids: [Int]?
    let score: Int?
    let time: Int?
    let title: String?
    let type: String?
    let url: String?
}
