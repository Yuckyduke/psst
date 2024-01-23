import Foundation
import Parsing

struct Message: Equatable {
  let prefix: Substring?
  let command: Substring
  let args: [Substring]?
}

// TODO: Support CR terminated lines (currently only support LF)
extension Message {
  // NUL, CR, LF, colon (`:`) and SPACE
  static let spcrlfcl = Set<Character>(["\0", "\r", "\n", ":", " "])
  
  static let nospcrlfcl = Parser
    .matchingAllCharacters(notIn: spcrlfcl)
    .flatMap { $0.isEmpty ? .never : .always($0) }
  
  static let withPrefix = zip(
    ":",
    .matchingAllCharacters(notIn: spcrlfcl),
    " "
  )
    .flatMap { _, pfx, _ in
      pfx.isEmpty ? .never : .always(pfx)
    }
  
  static let numericCommand: Parser<Substring> = zip(
    .prefix(while: \.isNumber)
    .flatMap {
      $0.count == 3 ? .always($0) : .never
    }, .oneOf(" ", "\n")
  ).map(\.0)
  
  static let wordCommand: Parser<Substring> = zip(
    .prefix(while: \.isLetter)
    .flatMap { $0.isEmpty ? .never : .always($0) },
    .oneOf(" ", "\n")
  ).map(\.0)
  
  static let command: Parser<Message> = Parser<Substring>.oneOf(
    numericCommand,
    wordCommand
  ).map { .init(prefix: nil, command: $0, args: nil) }
  
  static let colon: Parser<Substring> = zip(
    .char(":"),
    "\n"
  ).map({ _, _ in "" })
  
  static let trailingParameter: Parser<Substring> = .oneOf(
    colon, zip(
      ":",
      .matchingAllCharacters(
        notIn: spcrlfcl.subtracting([":", " "])
      ), "\n"
    ).flatMap({ _, pfx, _ in
      pfx.isEmpty ? .never : .always(pfx)
    }))
  
  static let middleParameter: Parser<Substring> = zip(
    .matchingAllCharacters(notIn: spcrlfcl),
    .matchingAllCharacters(notIn: spcrlfcl.subtracting([":"]))
  ).flatMap({ first, second in
    first.isEmpty ? .never : .always(first + second)
  })
  
  static let onlyMiddleParameters = zip(
    middleParameter.zeroOrMore(separatedBy: " "),
    "\n"
  ).map(\.0)
  
  static let middleAndTrailing: Parser<[Substring]> = zip(
    middleParameter.zeroOrMore(separatedBy: " "),
    " ",
    trailingParameter
  ).map{ middle, _, trailing in
    middle + [trailing]
  }
  
  static let params: Parser<[Substring]> = .oneOf(
    middleAndTrailing,
    onlyMiddleParameters,
    trailingParameter.map({ [$0] })
  )
  
  static let prefixAndCommand: Parser<Message> = zip(
    withPrefix, command
  ).map {
    .init(prefix: $0, command: $1.command, args: nil)
  }
  
  static let parse: Parser<Message> = zip(
    .oneOf(
      prefixAndCommand,
      command
    ),
    params
  ).map { .init(prefix: $0.prefix, command: $0.command, args: $1) }
}
