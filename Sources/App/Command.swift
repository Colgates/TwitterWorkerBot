//
//  File.swift
//  
//
//  Created by Evgenii Kolgin on 22.10.2022.
//

import Foundation

enum Command {
    case add, check, delete, deleteAll, refresh, getTweets
    
    var name: String {
        switch self {
        case .add:
            return "/add"
        case .check:
            return "/check"
        case .delete:
            return "/delete"
        case .deleteAll:
            return "/deleteall"
        case .refresh:
            return "/refresh"
        case .getTweets:
            return "/gettweets"
        }
    }
}
