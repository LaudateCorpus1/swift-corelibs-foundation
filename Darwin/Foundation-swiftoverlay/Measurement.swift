//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_exported import Foundation // Clang module

/// A `Measurement` is a model type that holds a `Double` value associated with a `Unit`.
///
/// Measurements support a large set of operators, including `+`, `-`, `*`, `/`, and a full set of comparison operators.
@available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
public struct Measurement<UnitType : Unit> : ReferenceConvertible, Comparable, Equatable {
    public typealias ReferenceType = NSMeasurement

    /// The unit component of the `Measurement`.
    public let unit: UnitType

    /// The value component of the `Measurement`.
    public var value: Double
    
    /// Create a `Measurement` given a specified value and unit.
    public init(value: Double, unit: UnitType) {
        self.value = value
        self.unit = unit
    }
    
    public var hashValue: Int {
        return Int(bitPattern: __CFHashDouble(value))
    }
}

@available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
extension Measurement : CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        return "\(value) \(unit.symbol)"
    }
    
    public var debugDescription: String {
        return "\(value) \(unit.symbol)"
    }
    
    public var customMirror: Mirror {
        var c: [(label: String?, value: Any)] = []
        c.append((label: "value", value: value))
        c.append((label: "unit", value: unit.symbol))
        return Mirror(self, children: c, displayStyle: Mirror.DisplayStyle.struct)
    }
}


/// When a `Measurement` contains a `Dimension` unit, it gains the ability to convert between the kinds of units in that dimension.
@available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
extension Measurement where UnitType : Dimension {
    /// Returns a new measurement created by converting to the specified unit.
    ///
    /// - parameter otherUnit: A unit of the same `Dimension`.
    /// - returns: A converted measurement.
    public func converted(to otherUnit: UnitType) -> Measurement<UnitType> {
        if unit.isEqual(otherUnit) {
            return Measurement(value: value, unit: otherUnit)
        } else {
            let valueInTermsOfBase = unit.converter.baseUnitValue(fromValue: value)
            if otherUnit.isEqual(type(of: unit).baseUnit()) {
                return Measurement(value: valueInTermsOfBase, unit: otherUnit)
            } else {
                let otherValueFromTermsOfBase = otherUnit.converter.value(fromBaseUnitValue: valueInTermsOfBase)
                return Measurement(value: otherValueFromTermsOfBase, unit: otherUnit)
            }
        }
    }
    
    /// Converts the measurement to the specified unit.
    ///
    /// - parameter otherUnit: A unit of the same `Dimension`.
    public mutating func convert(to otherUnit: UnitType) {
        self = converted(to: otherUnit)
    }

    /// Add two measurements of the same Dimension.
    /// 
    /// If the `unit` of the `lhs` and `rhs` are `isEqual`, then this returns the result of adding the `value` of each `Measurement`. If they are not equal, then this will convert both to the base unit of the `Dimension` and return the result as a `Measurement` of that base unit.
    /// - returns: The result of adding the two measurements.
    public static func +(lhs: Measurement<UnitType>, rhs: Measurement<UnitType>) -> Measurement<UnitType> {
        if lhs.unit.isEqual(rhs.unit) {
            return Measurement(value: lhs.value + rhs.value, unit: lhs.unit)
        } else {
            let lhsValueInTermsOfBase = lhs.unit.converter.baseUnitValue(fromValue: lhs.value)
            let rhsValueInTermsOfBase = rhs.unit.converter.baseUnitValue(fromValue: rhs.value)
            return Measurement(value: lhsValueInTermsOfBase + rhsValueInTermsOfBase, unit: type(of: lhs.unit).baseUnit())
        }
    }

    /// Subtract two measurements of the same Dimension.
    ///
    /// If the `unit` of the `lhs` and `rhs` are `==`, then this returns the result of subtracting the `value` of each `Measurement`. If they are not equal, then this will convert both to the base unit of the `Dimension` and return the result as a `Measurement` of that base unit.
    /// - returns: The result of adding the two measurements.
    public static func -(lhs: Measurement<UnitType>, rhs: Measurement<UnitType>) -> Measurement<UnitType> {
        if lhs.unit == rhs.unit {
            return Measurement(value: lhs.value - rhs.value, unit: lhs.unit)
        } else {
            let lhsValueInTermsOfBase = lhs.unit.converter.baseUnitValue(fromValue: lhs.value)
            let rhsValueInTermsOfBase = rhs.unit.converter.baseUnitValue(fromValue: rhs.value)
            return Measurement(value: lhsValueInTermsOfBase - rhsValueInTermsOfBase, unit: type(of: lhs.unit).baseUnit())
        }
    }
}

@available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
extension Measurement {
    /// Add two measurements of the same Unit.
    /// - precondition: The `unit` of `lhs` and `rhs` must be `isEqual`.
    /// - returns: A measurement of value `lhs.value + rhs.value` and unit `lhs.unit`.
    public static func +(lhs: Measurement<UnitType>, rhs: Measurement<UnitType>) -> Measurement<UnitType> {
        if lhs.unit.isEqual(rhs.unit) {
            return Measurement(value: lhs.value + rhs.value, unit: lhs.unit)
        } else {
            fatalError("Attempt to add measurements with non-equal units")
        }
    }

    /// Subtract two measurements of the same Unit.
    /// - precondition: The `unit` of `lhs` and `rhs` must be `isEqual`.
    /// - returns: A measurement of value `lhs.value - rhs.value` and unit `lhs.unit`.
    public static func -(lhs: Measurement<UnitType>, rhs: Measurement<UnitType>) -> Measurement<UnitType> {
        if lhs.unit.isEqual(rhs.unit) {
            return Measurement(value: lhs.value - rhs.value, unit: lhs.unit)
        } else {
            fatalError("Attempt to subtract measurements with non-equal units")
        }
    }

    /// Multiply a measurement by a scalar value.
    /// - returns: A measurement of value `lhs.value * rhs` with the same unit as `lhs`.
    public static func *(lhs: Measurement<UnitType>, rhs: Double) -> Measurement<UnitType> {
        return Measurement(value: lhs.value * rhs, unit: lhs.unit)
    }

    /// Multiply a scalar value by a measurement.
    /// - returns: A measurement of value `lhs * rhs.value` with the same unit as `rhs`.
    public static func *(lhs: Double, rhs: Measurement<UnitType>) -> Measurement<UnitType> {
        return Measurement(value: lhs * rhs.value, unit: rhs.unit)
    }

    /// Divide a measurement by a scalar value.
    /// - returns: A measurement of value `lhs.value / rhs` with the same unit as `lhs`.
    public static func /(lhs: Measurement<UnitType>, rhs: Double) -> Measurement<UnitType> {
        return Measurement(value: lhs.value / rhs, unit: lhs.unit)
    }

    /// Divide a scalar value by a measurement.
    /// - returns: A measurement of value `lhs / rhs.value` with the same unit as `rhs`.
    public static func /(lhs: Double, rhs: Measurement<UnitType>) -> Measurement<UnitType> {
        return Measurement(value: lhs / rhs.value, unit: rhs.unit)
    }

    /// Compare two measurements of the same `Dimension`.
    ///
    /// If `lhs.unit == rhs.unit`, returns `lhs.value == rhs.value`. Otherwise, converts `rhs` to the same unit as `lhs` and then compares the resulting values.
    /// - returns: `true` if the measurements are equal.
    public static func ==<LeftHandSideType : Unit, RightHandSideType : Unit>(_ lhs: Measurement<LeftHandSideType>, _ rhs: Measurement<RightHandSideType>) -> Bool {
        if lhs.unit == rhs.unit {
            return lhs.value == rhs.value
        } else {
            if let lhsDimensionalUnit = lhs.unit as? Dimension,
               let rhsDimensionalUnit = rhs.unit as? Dimension {
                if type(of: lhsDimensionalUnit).baseUnit() == type(of: rhsDimensionalUnit).baseUnit() {
                    let lhsValueInTermsOfBase = lhsDimensionalUnit.converter.baseUnitValue(fromValue: lhs.value)
                    let rhsValueInTermsOfBase = rhsDimensionalUnit.converter.baseUnitValue(fromValue: rhs.value)
                    return lhsValueInTermsOfBase == rhsValueInTermsOfBase
                }
            }
            return false
        }
    }

    /// Compare two measurements of the same `Unit`.
    /// - returns: `true` if the measurements can be compared and the `lhs` is less than the `rhs` converted value.
    public static func <<LeftHandSideType : Unit, RightHandSideType : Unit>(lhs: Measurement<LeftHandSideType>, rhs: Measurement<RightHandSideType>) -> Bool {
        if lhs.unit == rhs.unit {
            return lhs.value < rhs.value
        } else {
            if let lhsDimensionalUnit = lhs.unit as? Dimension,
               let rhsDimensionalUnit = rhs.unit as? Dimension {
                if type(of: lhsDimensionalUnit).baseUnit() == type(of: rhsDimensionalUnit).baseUnit() {
                    let lhsValueInTermsOfBase = lhsDimensionalUnit.converter.baseUnitValue(fromValue: lhs.value)
                    let rhsValueInTermsOfBase = rhsDimensionalUnit.converter.baseUnitValue(fromValue: rhs.value)
                    return lhsValueInTermsOfBase < rhsValueInTermsOfBase
                }
            }
            fatalError("Attempt to compare measurements with non-equal dimensions")
        }
    }
}

// Implementation note: similar to NSArray, NSDictionary, etc., NSMeasurement's import as an ObjC generic type is suppressed by the importer. Eventually we will need a more general purpose mechanism to correctly import generic types.

@available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
extension Measurement : _ObjectiveCBridgeable {
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSMeasurement {
        return NSMeasurement(doubleValue: value, unit: unit)
    }
    
    public static func _forceBridgeFromObjectiveC(_ source: NSMeasurement, result: inout Measurement?) {
        result = Measurement(value: source.doubleValue, unit: source.unit as! UnitType)
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ source: NSMeasurement, result: inout Measurement?) -> Bool {
        if let u = source.unit as? UnitType {
            result = Measurement(value: source.doubleValue, unit: u)
            return true
        } else {
            return false
        }
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSMeasurement?) -> Measurement {
        let u = source!.unit as! UnitType
        return Measurement(value: source!.doubleValue, unit: u)
    }
}

@available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
extension NSMeasurement : _HasCustomAnyHashableRepresentation {
    // Must be @nonobjc to avoid infinite recursion during bridging.
    @nonobjc
    public func _toCustomAnyHashable() -> AnyHashable? {
        return AnyHashable(self as Measurement)
    }
}

// This workaround is required for the time being, because Swift doesn't support covariance for Measurement (26607639)
@available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
extension MeasurementFormatter {
    public func string<UnitType: Unit>(from measurement: Measurement<UnitType>) -> String {
        if let result = string(for: measurement) {
            return result
        } else {
            return ""
        }
    }
}
