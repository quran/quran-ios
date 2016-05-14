//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright © 2014-2015 Stephen Celis.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import CSQLite

public typealias Star = (Expression<Binding>?, Expression<Binding>?) -> Expression<Void>

public func *(_: Expression<Binding>?, _: Expression<Binding>?) -> Expression<Void> {
    return Expression(literal: "*")
}

public protocol _OptionalType {

    associatedtype WrappedType

}

extension Optional : _OptionalType {

    public typealias WrappedType = Wrapped

}

// let SQLITE_STATIC = unsafeBitCast(0, sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, sqlite3_destructor_type.self)

extension String {

    @warn_unused_result func quote(mark: Character = "\"") -> String {
        let escaped = characters.reduce("") { string, character in
            string + (character == mark ? "\(mark)\(mark)" : "\(character)")
        }
        return "\(mark)\(escaped)\(mark)"
    }

    @warn_unused_result func join(expressions: [Expressible]) -> Expressible {
        var (template, bindings) = ([String](), [Binding?]())
        for expressible in expressions {
            let expression = expressible.expression
            template.append(expression.template)
            bindings.appendContentsOf(expression.bindings)
        }
        return Expression<Void>(template.joinWithSeparator(self), bindings)
    }

    @warn_unused_result func infix<T>(lhs: Expressible, _ rhs: Expressible, wrap: Bool = true) -> Expression<T> {
        let expression = Expression<T>(" \(self) ".join([lhs, rhs]).expression)
        guard wrap else {
            return expression
        }
        return "".wrap(expression)
    }

    @warn_unused_result func prefix(expressions: Expressible) -> Expressible {
        return "\(self) ".wrap(expressions) as Expression<Void>
    }

    @warn_unused_result func prefix(expressions: [Expressible]) -> Expressible {
        return "\(self) ".wrap(expressions) as Expression<Void>
    }

    @warn_unused_result func wrap<T>(expression: Expressible) -> Expression<T> {
        return Expression("\(self)(\(expression.expression.template))", expression.expression.bindings)
    }

    @warn_unused_result func wrap<T>(expressions: [Expressible]) -> Expression<T> {
        return wrap(", ".join(expressions))
    }

}

@warn_unused_result func infix<T>(lhs: Expressible, _ rhs: Expressible, wrap: Bool = true, function: String = #function) -> Expression<T> {
    return function.infix(lhs, rhs, wrap: wrap)
}

@warn_unused_result func wrap<T>(expression: Expressible, function: String = #function) -> Expression<T> {
    return function.wrap(expression)
}

@warn_unused_result func wrap<T>(expressions: [Expressible], function: String = #function) -> Expression<T> {
    return function.wrap(", ".join(expressions))
}

@warn_unused_result func transcode(literal: Binding?) -> String {
    guard let literal = literal else { return "NULL" }

    switch literal {
    case let blob as Blob:
        return blob.description
    case let string as String:
        return string.quote("'")
    case let binding:
        return "\(binding)"
    }
}

@warn_unused_result func value<A: Value>(v: Binding) -> A {
    return A.fromDatatypeValue(v as! A.Datatype) as! A
}

@warn_unused_result func value<A: Value>(v: Binding?) -> A {
    return value(v!)
}
