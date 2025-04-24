//
//  Calculator.swift
//  calc
//
//  Created by Jacktator on 31/3/20.
//  Copyright © 2020 UTS. All rights reserved.
//

import Foundation


// Define an enumeration named CalculatorError that conforms to the Error protocol
enum CalculatorError: Error {
    case divisionByZero
    case overflow
    case invalidInput(String)
    case unknownOperator(String)
}


class Calculator {
    
    /// For multi-step calculation, it's helpful to persist existing result
    var currentResult = 0;
    
    /// Perform Addition
    ///
    /// - Author: Jacktator
    /// - Parameters:
    ///   - no1: First number
    ///   - no2: Second number
    /// - Returns: The addition result
    ///
    /// - Warning: The result may yield Int overflow.
    /// - SeeAlso: https://developer.apple.com/documentation/swift/int/2884663-addingreportingoverflow
    
    
    
    // Addition
    func add(no1: Int, no2: Int) throws -> Int {
        let (result, overflow) = no1.addingReportingOverflow(no2)
        if overflow {
            throw CalculatorError.overflow
        }
        return result
    }
    
    // Subtraction with underflow check
    func diff(no1: Int, no2: Int) throws -> Int {
        let (result, overflow) = no1.subtractingReportingOverflow(no2)
        if overflow {
            throw CalculatorError.overflow
        }
        return result
    }
    
    // Multiplication with overflow check
    func product(no1: Int, no2: Int) throws -> Int {
        let (result, overflow) = no1.multipliedReportingOverflow(by: no2)
        if overflow {
            throw CalculatorError.overflow
        }
        return result
    }
    
    // Division
    func quotient(no1: Int, no2: Int) throws -> Int {
        guard no2 != 0 else {
            throw CalculatorError.divisionByZero
        }
        return no1 / no2
    }
    
    
    // Remainder
    func remainder(no1: Int, no2: Int) -> Int{
        return no1 % no2;
    }
    
    
    // Maps operators to their arithmetic functions, with checks for division by zero
    private let operations: [String: (Int, Int) throws -> Int] = [
        "+": { no1, no2 in no1 + no2 },
        "-": { no1, no2 in no1 - no2 },
        "*": { no1, no2 in no1 * no2 },
        "x": { no1, no2 in no1 * no2 },
        "/": { no1, no2 in
            if no2 == 0 {
                throw CalculatorError.divisionByZero
            }
            return no1 / no2
        },
        "%": { no1, no2 in
            if no2 == 0 {
                throw CalculatorError.divisionByZero
            }
            return no1 % no2
        }
    ]
    
    
    // Checks if op1 has equal or higher precedence than op2
    
    private func hasPrecedence(op1: String, op2: String) -> Bool {
        let precedence: [String: Int] = ["+": 1, "-": 1, "*": 2, "x":2, "/": 2, "%": 2]
        let op1Precedence = precedence[op1] ?? 0
        let op2Precedence = precedence[op2] ?? 0
        return op1Precedence >= op2Precedence
    }
    
    
    
    func calculate(args: [String]) throws -> Int {
        var nums = [Int]()
        var ops = [String]()
        
        
        if args.count == 1, let num = Int(args[0]) {
            return num
        }
        
        for arg in args {
            if let num = Int(arg) {
                nums.append(num)
            } else if operations.keys.contains(arg) {
                while let lastOp = ops.last, hasPrecedence(op1: lastOp, op2: arg) {
                    let op = ops.removeLast()
                    let right = nums.removeLast()
                    let left = nums.removeLast()
                    let result = try performOperation(op: op, left: left, right: right)
                    nums.append(result)
                }
                ops.append(arg)
            } else if Double(arg) != nil {
                throw CalculatorError.invalidInput("Invalid input: \(arg)")
            } else {
                throw CalculatorError.unknownOperator("Unknown operator: \(arg)")
            }
        }
        
        while !ops.isEmpty {
            let op = ops.removeLast()
            if nums.count < 2 {
                throw CalculatorError.invalidInput("Insufficient operands for operation \(op).")
            }
            let right = nums.removeLast()
            let left = nums.removeLast()
            let result = try performOperation(op: op, left: left, right: right)
            nums.append(result)
        }
        
        return nums.last ?? 0
    }
    
    
    
    // Executes the operation based on the operator, handling overflows and division by zero
    
    private func performOperation(op: String, left: Int, right: Int) throws -> Int {
        switch op {
        case "+":
            let (result, overflow) = left.addingReportingOverflow(right)
            if overflow {
                throw CalculatorError.overflow
            }
            return result
        case "-":
            let (result, overflow) = left.subtractingReportingOverflow(right)
            if overflow {
                throw CalculatorError.overflow
            }
            return result
        case "*", "x":
            let (result, overflow) = left.multipliedReportingOverflow(by: right)
            if overflow {
                throw CalculatorError.overflow
            }
            return result
        case "/":
            guard right != 0 else {
                throw CalculatorError.divisionByZero
            }
            return left / right
        case "%":
            guard right != 0 else {
                throw CalculatorError.divisionByZero
            }
            return left % right
        default:
            throw CalculatorError.unknownOperator(op)
        }
    }
}

// Validates input arguments for calculator usage, ensuring they meet expected formats
class InputValidator {
    static func validate(args: [String]) -> Bool {
        if args.count == 1 {
            let input = args[0]
            if let _ = Int(input) {
                return true
            } else if let firstChar = input.first, (firstChar == "+" || firstChar == "-"), let _ = Int(input.dropFirst()) {
                return true
            } else {
                print("Invalid input: \(input)")
                return false
            }
        } else if args.count < 3 || args.count % 2 != 1 {
            print("Usage: calc [number][operator][number]")
            return false
        }
        return true
    }
}


// Application execution manager with error handling
struct AppRunner {
        private let calculator = Calculator()
    
    func run(withArguments args: [String]) {
            guard InputValidator.validate(args: args) else {
                exit(1)
            }
            
            do {
                let result = try calculator.calculate(args: args)
                print(result)
            } catch let error {
                handleError(error)
            }
        }
    
    
    // Handles calculation errors and exits the application.
        private func handleError(_ error: Error) {
            if let calcError = error as? CalculatorError {
                switch calcError {
                case .divisionByZero:
                    print("Error: Cannot divide by zero.")
                case .overflow:
                    print("Error: Calculation overflowed.")
                case .invalidInput(let message):
                    print("Error: \(message)")
                case .unknownOperator(let op):
                    print("Error: Unknown operator \(op).")
                }
            } else {
                print("An unknown error occurred.")
            }
            exit(1)
        }
    }


