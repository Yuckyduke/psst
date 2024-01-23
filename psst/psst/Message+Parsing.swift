import Foundation

struct Message {
  let prefix: String?
  let command: String
  let args: [String]
}

struct Parser<A> {
  let run: (inout Substring) -> A?
  
  func run(_ str: String) -> (match: A?, rest: Substring){
    var str = str[...]
    let match = self.run(&str)
    return (match, str)
  }
}
extension Parser {
  func map<B>(_ f: @escaping (A) -> B) -> Parser<B> {
    return Parser<B> { str -> B? in
      self.run(&str).map(f)
    }
  }
  
  func flatMap<B>(_ f: @escaping (A) -> Parser<B>) -> Parser<B> {
    return Parser<B> { str -> B? in
      let original = str
      let matchA = self.run(&str)
      let parserB = matchA.map(f)
      guard let matchB = parserB?.run(&str) else {
        str = original
        return nil
      }
      return matchB
    }
  }
}

func zip<A, B>(_ a: Parser<A>, _ b: Parser<B>) -> Parser<(A, B)> {
  return Parser<(A, B)> { str -> (A, B)? in
    let original = str
    guard let matchA = a.run(&str) else {
      return nil
    }
    guard let matchB = b.run(&str) else {
      str = original
      return nil
    }
    return (matchA, matchB)
  }
}

// MARK: zip overloads
func zip<A, B, C>(
  _ a: Parser<A>,
  _ b: Parser<B>,
  _ c: Parser<C>
) -> Parser<(A, B, C)> {
  return zip(a, zip(b, c))
    .map { a, bc in (a, bc.0, bc.1) }
}

func zip<A, B, C, D>(
  _ a: Parser<A>,
  _ b: Parser<B>,
  _ c: Parser<C>,
  _ d: Parser<D>
) -> Parser<(A, B, C, D)> {
  return zip(a, zip(b, c, d))
    .map { a, bcd in (a, bcd.0, bcd.1, bcd.2) }
}

func zip<A, B, C, D, E>(
  _ a: Parser<A>,
  _ b: Parser<B>,
  _ c: Parser<C>,
  _ d: Parser<D>,
  _ e: Parser<E>
) -> Parser<(A, B, C, D, E)> {
  return zip(a, zip(b, c, d, e))
    .map { a, bcde in (a, bcde.0, bcde.1, bcde.2, bcde.3) }
}

// MARK: Always/Never parsers
// always succeeds
func always<A>(_ a: A) -> Parser<A> {
  return Parser<A> { _ in a }
}

extension Parser {
  // always fails
  static var never: Parser {
    return Parser { _ in nil }
  }
}

// MARK: Prefix funcs
// returns a Parser<Substring> that prefixes until predicate fails
func prefix(while p: @escaping (Character) -> Bool) -> Parser<Substring> {
  return Parser<Substring> { str in
    let prefix = str.prefix(while: p)
    str.removeFirst(prefix.count)
    return prefix
  }
}

// Prefixes so long as characters not contained in given set
func matchingAllCharacters(notIn set: Set<Character>) -> Parser<Substring> {
  return prefix(while: { !set.contains($0) })
}

// fails parse if not satisfied but does not consume character either way
// kind of like a lookahead I think, but might be strange.
// I know the whole point of these parsers is that you
// have to consume something but idk how to perform this check otherwise
func startsWithCharacter(notIn set: Set<Character>) -> Parser<Void> {
  return Parser<Void> { str in
    if let first = str.first {
      return set.contains(first) ? nil : ()
    }
    return ()
  }
}

// parses literal off begining of string
func literal(_ p: String) -> Parser<Void> {
  return Parser<Void> { str in
    guard str.hasPrefix(p) else { return nil }
    str.removeFirst(p.count)
    return ()
  }
}

let char = Parser<Character> { str in
  guard !str.isEmpty else { return nil }
  return str.removeFirst()
}


// MARK: oneOf(_:), zeroOrMoreSpaces, oneOrMoreSpaces, zeroOrMore(_:)
// returns the first parser that succeeds
func oneOf<A>(_ ps: [Parser<A>]) -> Parser<A> {
  return Parser<A> { str -> A? in
    for p in ps {
      if let match = p.run(&str) {
        return match
      }
    }
    return nil
  }
}

// Variadic overload of `oneOf`, use this one over array version
func oneOf<A>(_ ps: Parser<A>...) -> Parser<A> {
  return oneOf(ps)
}

let zeroOrMoreSpaces = prefix { $0 == " " }.map { _ in }
let oneOrMoreSpaces = prefix { $0 == " " }.flatMap {
  $0.isEmpty ? .never : always(())
}

func zeroOrMore<A>(
  _ p: Parser<A>,
  separatedBy s: Parser<Void>
) -> Parser<[A]> {
  return Parser<[A]> { str in
    var matches: [A] = []
    var rest = str
    while let match = p.run(&str) {
      rest = str
      matches.append(match)
      if s.run(&str) == nil {
        return matches
      }
    }
    str = rest
    return matches
  }
}

// "optional" parser
// Function that wraps another parser in a parser that always
// succeeds and is allowed to return nil.
// I came up with this but am still kind of confused why it works.
func optionally<A>(_ p: Parser<A>) -> Parser<A?> {
  return oneOf(Parser<A?> { str in
    let original = str
    guard let match = p.run(&str)
    else {
      str = original
      return nil
    }
    return match
  }, always(nil))
}

// MARK: IRC specific parsers
// NUL, CR, LF, colon (`:`) and SPACE
let spcrlfcl = Set<Character>(["\0", "\r", "\n", ":", " "])

let nospcrlfcl = matchingAllCharacters(notIn: spcrlfcl)
  .flatMap { $0.isEmpty ? .never : always($0) }

// fails if no ":" at beginning
let withPrefix = zip(
  literal(":"),
  prefix(while: { $0 != " "})
).flatMap { _, pfx in
  pfx.isEmpty ? .never : always(pfx)
}

let messagePrefix = optionally(withPrefix)

// Just namespaced for convenience
enum Parameter {
  // middle ::=  nospcrlfcl zeroOrMore( ":" / nospcrlfcl )
  // first character cannot be ":"
  static let middle = zip(
    startsWithCharacter(notIn: spcrlfcl),
    matchingAllCharacters(notIn:  spcrlfcl.subtracting([":"]))
  ).map(\.1)
  
  // trailing ::=  zeroOrMore( ":" / " " / nospcrlfcl )
  static let trailing = zip(
    literal(" :"),
    matchingAllCharacters(
      notIn: spcrlfcl.subtracting([":", " "])
    )).map(\.1)
}


let parameters = zip(
  zeroOrMore(Parameter.middle, separatedBy: literal(" ")), // zeroOrMore( SPACE middle )
  optionally(Parameter.trailing) // SPACE ":" trailing
).map { middle, trailing in
  trailing.map({ middle + [$0] }) ?? middle
}

// parameter ::=  zeroOrMore( SPACE middle ) Optional[ SPACE ":" trailing ]
let message: Parser<Message> = zip(
  messagePrefix,
  zeroOrMoreSpaces,
  nospcrlfcl, // unsure if command is allowed to include ":"
  zeroOrMoreSpaces,
  parameters
).map { pfx, _, cmd, _, args in
  Message(
    prefix: pfx.map(String.init),
    command: String(cmd),
    args: args.map(String.init)
  )
}

// got this from https://modern.ircdocs.horse/#parameters
let testMessages = [
  ":irc.example.com CAP * LIST :", // params ["*", "LIST", ""]
  "CAP * LS :multi-prefix sasl", // params ["*", "LS", "multi-prefix sasl"]
  "CAP REQ :sasl message-tags foo", // params ["REQ", "sasl message-tags foo"]
  ":dan!d@localhost PRIVMSG #chan Hey!", // params ["#chan", "Hey!"]
  ":dan!d@localhost PRIVMSG #chan :Hey!", // params ["#chan", "Hey!"]
  ":dan!d@localhost PRIVMSG #chan ::-)" // params ["#chan", ":-)"]
]


let clock = ContinuousClock()
// forcing stuff to initialize before testing parsing speed
//print(message.run("Hello world!!!").match ?? "")
// ~.0001 seconds to parse
let result = clock.measure {
  testMessages.forEach { testMessage in
    print(message.run(testMessage).match ?? "")
  }
}

//print(result)

