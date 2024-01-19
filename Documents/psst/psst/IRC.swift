//
//  IRC.swift
//  psst
//
//  Created by Matthew Brown on 1/16/24.
//
//message    =  [ ":" prefix SPACE ] command [ params ] crlf
//prefix     =  servername / ( nickname [ [ "!" user ] "@" host ] )
//command    =  1*letter / 3digit
//params     =  *14( SPACE middle ) [ SPACE ":" trailing ]
//           =/ 14( SPACE middle ) [ SPACE [ ":" ] trailing ]
//
//nospcrlfcl =  %x01-09 / %x0B-0C / %x0E-1F / %x21-39 / %x3B-FF
//                ; any octet except NUL, CR, LF, " " and ":"
//middle     =  nospcrlfcl *( ":" / nospcrlfcl )
//trailing   =  *( ":" / " " / nospcrlfcl )
//
//SPACE      =  %x20        ; space character
//crlf       =  %x0D %x0A   ; "carriage return" "linefeed"

import Foundation
let cheese = [Channel(id: "Poop")]
struct Message {
    let prefix: String
    let command: String
    let args: [String]
}

func parseMsg(s: String) -> Message{
    /*
     takes a String from an IRC server and returns a Message
        Each IRC message may consist of up to three main parts: the prefix
        (optional), the command, and the command parameters (of which there
        may be up to 15).  The prefix, command, and all parameters are
        separated by one (or more) ASCII space character(s) (0x20).
     */
    var buffer = s
    var prefix = ""
    var trailing: [String] = []
    var args: [String] = []
    var command: String = ""
    if buffer == ""{
        print("Empty Message") // TODO: error handling
    }
    if buffer[buffer.startIndex] == ":"{
        var split = buffer.split(separator: " ", maxSplits: 1).map {String($0)}
        prefix = split[0]
        buffer = split[1]
    }
    if let range = buffer.range(of: " :"){
        if range.upperBound < buffer.endIndex{
            var split = buffer.split(separator: " :", maxSplits: 1).map {String($0)}
            buffer = split[0]
            trailing.append(split[1])
            args = buffer.split(separator: " ").map {String($0)}
            args.append(contentsOf: trailing)
        }
    }
    else {
        args = buffer.split(separator: " ").map {String($0)}
        command = args.removeFirst()
    }
    return Message(prefix: prefix, command: command, args: args)
}
struct User {
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
    
    mutating func goAway(){
        away = true
    }
    
}
struct Channel{
    var id: String
    var topic: String = "No Topic Set"
    init(id: String) {
        self.id = id
    }
    
    mutating func setTopic(newTopic: String){
        topic = newTopic
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

//struct Client: IRC_Client{
//    func message(_ command: Command, user: User) {
//        switch command{
//        case .pass(let passwd):
//            print(passwd)
//        case .nick(let nickname):
//            print(nickname)
//        case .user(let username, let mode, let realname):
//            print(username + String(mode) + realname)
//            print("poop")
//        case .join(let channel, let key):
//            print(channel + key!)
//        case .part(let channelList, let partMessage):
//            for channel in channelList{
//                print(channel)
//            }
//            print(partMessage!)
//        case .topic(let channel, let topic):
//            print(channel + topic!)
//            //            if user.channelPrivs.contains(channel){
//            //                if getChannel(id: channel) != nil {
//            //                    let topicChannel = getChannel(id: channel)
//            //                    if topic != nil{
//            //                        topicChannel.setTopic(topic: topic)
//            //                    }
//            //                }
//            //            }
//            //        }
//            //    }
//        }
//    }
//}
