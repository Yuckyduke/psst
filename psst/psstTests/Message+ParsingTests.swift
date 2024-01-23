//
//  psstTests.swift
//  psstTests
//
//  Created by Matthew Brown on 1/16/24.
//

import XCTest
@testable import psst

final class psstTests: XCTestCase {
  
  // messages have to be terminated by CR/LF (I didn't account for CR tho)
  struct TestMessage {
    let input: String
    let expectedOutput: Message
  }
  let testMessages: [TestMessage] = [
    .init(
      input: ":irc.example.com CAP * LIST :\n",
      expectedOutput: Message(
        prefix: "irc.example.com",
        command: "CAP",
        args: ["*", "LIST", ""]
      )),
    .init(
      input: "CAP * LS :multi-prefix sasl\n",
      expectedOutput: Message(
        prefix: nil,
        command: "CAP",
        args: ["*", "LS", "multi-prefix sasl"]
      )),
    .init(
      input: "CAP REQ :sasl message-tags foo\n",
      expectedOutput: Message(
        prefix: nil,
        command: "CAP",
        args: ["REQ", "sasl message-tags foo"]
      )),
    .init(
      input: ":dan!d@localhost PRIVMSG #chan Hey!\n",
      expectedOutput: Message(
        prefix: "dan!d@localhost",
        command: "PRIVMSG",
        args: ["#chan", "Hey!"]
      )),
    .init(
      input: ":dan!d@localhost PRIVMSG #chan :Hey!\n",
      expectedOutput: Message(
        prefix: "dan!d@localhost",
        command: "PRIVMSG",
        args: ["#chan", "Hey!"]
      )),
    .init(
      input: ":dan!d@localhost PRIVMSG #chan ::-)\n",
      expectedOutput: Message(
        prefix: "dan!d@localhost",
        command: "PRIVMSG",
        args: ["#chan", ":-)"]
      ))
  ]
  
  override func setUpWithError() throws {
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testMessageParsing() throws {
    testMessages.forEach { testMessage in
      let output = Message.parse.run(testMessage.input)
      XCTAssertEqual(output.match, testMessage.expectedOutput)
    }
  }
  
  func testPerformanceExample() throws {
    self.measure {
    }
  }
}
