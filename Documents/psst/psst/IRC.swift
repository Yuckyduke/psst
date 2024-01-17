//
//  IRC.swift
//  psst
//
//  Created by Matthew Brown on 1/16/24.
//

import Foundation
let cheese = [Channel(id: "Poop")]
 class User {
    var username: String
    var mode: Int
    var realname: String
    var away: Bool = false
    var channelPrivs: [String]
    init(username: String, mode: Int, realname: String, away: Bool) {
        self.username = username
        self.mode = mode
        self.realname = realname
        self.away = away
        self.channelPrivs = []
    }
    
    func goAway(){
        self.away = true
    }
    
}
class Channel{
    var id: String
    var topic: String = "No Topic Set"
    init(id: String) {
        self.id = id
    }
    
    func setTopic(topic: String){
        self.topic = topic
    }
}

func getChannel(id: String) -> Channel?{
    for channel in cheese{
        if channel.id == id{
            return channel
        }
    }
    return nil
}

enum Command {
    case pass (passwd: String)
    case nick (nickname: String)
    case user (username: String, mode: Int, realname: String)
    case join(channel: String, key: String?)
    case part(channelList: [String], partMessage: String?)
    case topic(channel: String, topic: String?)
}

enum Mode{
    case a
    case i
    case w
    case r
    case o
    case O
    case s
}

protocol IRC_Client{
    func message(_ command: Command, user: User)
}

struct Client: IRC_Client{
    func message(_ command: Command, user: User) {
        switch command{
        case .pass(let passwd):
            print(passwd)
        case .nick(let nickname):
            print(nickname)
        case .user(let username, let mode, let realname):
            print(username + String(mode) + realname)
            print("poop")
        case .join(let channel, let key):
            print(channel + key!)
        case .part(let channelList, let partMessage):
            for channel in channelList{
                print(channel)
            }
            print(partMessage!)
        case .topic(let channel, let topic):
            print(channel + topic!)
            //            if user.channelPrivs.contains(channel){
            //                if getChannel(id: channel) != nil {
            //                    let topicChannel = getChannel(id: channel)
            //                    if topic != nil{
            //                        topicChannel.setTopic(topic: topic)
            //                    }
            //                }
            //            }
            //        }
            //    }
        }
    }
}
