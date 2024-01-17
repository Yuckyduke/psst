//
//  IRC.swift
//  psst
//
//  Created by Matthew Brown on 1/16/24.
//

import Foundation

class User {
    var username: String
    var mode: Int
    var realname: String
    var away: Bool = false
    init(username: String, mode: Int, realname: String, away: Bool) {
        self.username = username
        self.mode = mode
        self.realname = realname
        self.away = away
    }
    
    func goAway(){
        self.away = true
    }
    
}

enum Command {
    case pass (passwd: String)
    case nick (nickname: String)
    case user (username: String, mode: Int, unused: String, realname: String)
}

enum Mode{
    case a ()
    case i
    case w
    case r
    case o
    case O
    case s
}

protocol IRC_Client{
    func message(_ command: Command)
}

struct Client: IRC_Client{
    func message(_ command: Command) {
        switch command{
        case .pass(let passwd):
            print(passwd)
        case .nick(let nickname):
            print(nickname)
        case .user:
            print("Yo")
        }
    }
}
