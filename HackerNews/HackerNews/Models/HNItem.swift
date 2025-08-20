//
//  HNItem.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/19/25.
//
/**
 Field    Description
 id    The item's unique id.
 deleted    true if the item is deleted.
 type    The type of item. One of "job", "story", "comment", "poll", or "pollopt".
 by    The username of the item's author.
 time    Creation date of the item, in Unix Time.
 text    The comment, story or poll text. HTML.
 dead    true if the item is dead.
 parent    The comment's parent: either another comment or the relevant story.
 poll    The pollopt's associated poll.
 kids    The ids of the item's comments, in ranked display order.
 url    The URL of the story.
 score    The story's score, or the votes for a pollopt.
 title    The title of the story, poll or job. HTML.
 parts    A list of related pollopts, in display order.
 descendants    In the case of stories or polls, the total comment count.
 */

import Foundation

enum ItemType: Codable {
    case job
    case story
    case comment
    case poll
    case pollopt
}

struct HNItem: Hashable, Codable {
    var id: Int
    var isDeleted: Bool?
    var type: ItemType?
    var by: String?
    var time: TimeInterval?
    var text: String?
    var isDead: Bool?
    var parent: Int?
    var poll: Int?
    var kids: [Int]?
    var url: String?
    var score: Int?
    var title: String?
    var parts: [String]?
    var descendants: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case id
        , type
        , by
        , time
        , text
        , parent
        , poll
        , kids
        , url
        , score
        , title
        , parts
        , descendants
        case isDeleted = "deleted"
        case isDead = "dead"
    }
}
