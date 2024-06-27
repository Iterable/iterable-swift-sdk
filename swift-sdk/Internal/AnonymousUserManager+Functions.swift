//
//  File.swift
//
//
//  Created by HARDIK MASHRU on 13/11/23.
//

import Foundation

// Convert commerce items to dictionaries
func convertCommerceItemsToDictionary(_ items: [CommerceItem]) -> [[AnyHashable:Any]] {
    let dictionaries = items.map { item in
        return item.toDictionary()
    }
    return dictionaries
}

// Convert to commerce items from dictionaries
func convertCommerceItems(from dictionaries: [[AnyHashable: Any]]) -> [CommerceItem] {
    return dictionaries.compactMap { dictionary in
        let item = CommerceItem(id: dictionary[JsonKey.CommerceItem.id] as? String ?? "", name: dictionary[JsonKey.CommerceItem.name] as? String ?? "", price: dictionary[JsonKey.CommerceItem.price] as? NSNumber ?? 0, quantity: dictionary[JsonKey.CommerceItem.quantity] as? UInt ?? 0)
        item.sku = dictionary[JsonKey.CommerceItem.sku] as? String
        item.itemDescription = dictionary[JsonKey.CommerceItem.description] as? String
        item.url = dictionary[JsonKey.CommerceItem.url] as? String
        item.imageUrl = dictionary[JsonKey.CommerceItem.imageUrl] as? String
        item.categories = dictionary[JsonKey.CommerceItem.categories] as? [String]
        item.dataFields = dictionary[JsonKey.CommerceItem.dataFields] as? [AnyHashable: Any]

        return item
    }
}

func convertToDictionary(data: Codable) -> [AnyHashable: Any] {
    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(data)
        if let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyHashable: Any] {
            return dictionary
        }
    } catch {
        print("Error converting to dictionary: \(error)")
    }
    return [:]
}

// Converts UTC Datetime from current time
func getUTCDateTime() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    dateFormatter.timeZone = TimeZone(identifier: "UTC")
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    
    let utcDate = Date()
    return dateFormatter.string(from: utcDate)
}

struct CriteriaCompletionChecker {
    init(anonymousCriteria: Data, anonymousEvents: [[AnyHashable: Any]]) {
        self.anonymousEvents = anonymousEvents
        self.anonymousCriteria = anonymousCriteria
    }
    
    func getMatchedCriteria() -> String? {
        var criteriaId: String? = nil
        if let json = try? JSONSerialization.jsonObject(with: anonymousCriteria, options: []) as? [String: Any] {
            // Access the criteriaList
            if let criteriaList = json[JsonKey.criterias] as? [[String: Any]] {
                // Iterate over the criteria
                for criteria in criteriaList {
                    // Perform operations on each criteria
                    if let searchQuery = criteria[JsonKey.CriteriaItem.searchQuery] as? [String: Any], let currentCriteriaId = criteria[JsonKey.CriteriaItem.criteriaId] as? String {
                        // we will split purhase/updatecart event items as seperate events because we need to compare it against the single item in criteria json
                        var eventsToProcess = getEventsWithCartItems()
                        eventsToProcess.append(contentsOf: getNonCartEvents())
                        let result = evaluateTree(node: searchQuery, localEventData: eventsToProcess)
                        if (result) {
                            criteriaId = currentCriteriaId
                            break
                        }
                    }
                }
            }
        }
        return criteriaId
    }
    
    func getMappedKeys(event: [AnyHashable: Any]) -> [String] {
        var itemKeys: [String] = []
        for (_ , value) in event {
            if let arrayValue = value as? [[AnyHashable: Any]], arrayValue.count > 0 { // this is a special case of items array in purchase event
                // If the value is an array, handle it
                itemKeys.append(contentsOf: extractKeys(dict: arrayValue[0]))
            } else {
                itemKeys.append(contentsOf: extractKeys(dict: event))
            }
        }
        return itemKeys
    }
    
    func getNonCartEvents() -> [[AnyHashable: Any]] {
        let nonPurchaseEvents = anonymousEvents.filter { dictionary in
            if let dataType = dictionary[JsonKey.eventType] as? String {
                return dataType != EventType.purchase && dataType != EventType.updateCart
            }
            return false
        }
        var processedEvents: [[AnyHashable: Any]] = [[:]]
        for eventItem in nonPurchaseEvents {
            var updatedItem = eventItem
            // handle dataFields if any
            if let dataFields = eventItem[JsonKey.CommerceItem.dataFields] as? [AnyHashable: Any] {
                for (key, value) in dataFields {
                    if key is String {
                        updatedItem[key] = value
                    }
                }
                updatedItem.removeValue(forKey: JsonKey.CommerceItem.dataFields)
            }
            processedEvents.append(updatedItem)
        }
        return processedEvents
    }
    
    func getEventsWithCartItems() -> [[AnyHashable: Any]] {
        var dataTypeEvent: String = "";
        let purchaseEvents = anonymousEvents.filter { dictionary in
            if let dataType = dictionary[JsonKey.eventType] as? String {
                dataTypeEvent = dataType;
                return dataType == EventType.purchase || dataType == EventType.updateCart
            }
            return false
        }
        
        var processedEvents: [[AnyHashable: Any]] = [[:]]
        for eventItem in purchaseEvents {
            if dataTypeEvent == EventType.purchase {
                if let items = eventItem[JsonKey.Commerce.items] as? [[AnyHashable: Any]] {
                    let itemsWithOtherProps = items.map { item -> [AnyHashable: Any] in
                        var updatedItem = [AnyHashable: Any]()
                        
                        for (key, value) in item {
                            if let stringKey = key as? String {
                                updatedItem["shoppingCartItems." + stringKey] = value
                            }
                        }
                        
                        // handle dataFields if any
                        if let dataFields = eventItem[JsonKey.CommerceItem.dataFields] as? [AnyHashable: Any] {
                            for (key, value) in dataFields {
                                if key is String {
                                    updatedItem[key] = value
                                }
                            }
                        }
                        
                        for (key, value) in eventItem {
                            if (key as! String != JsonKey.Commerce.items && key as! String != JsonKey.CommerceItem.dataFields) {
                                updatedItem[key] = value
                            }
                        }
                        return updatedItem
                    }
                    processedEvents.append(contentsOf: itemsWithOtherProps)
                }
            } else if dataTypeEvent == EventType.updateCart {
                let defaultEvent: [AnyHashable: Any] = [
                    JsonKey.eventType: EventType.customEvent,
                    JsonKey.eventName: EventType.updateCart
                ]
                processedEvents.append(defaultEvent)
                if let items = eventItem[JsonKey.Commerce.items] as? [[AnyHashable: Any]] {
                    let itemsWithOtherProps = items.map { item -> [AnyHashable: Any] in
                        var updatedItem = [AnyHashable: Any]()
                        
                        for (key, value) in item {
                            if let stringKey = key as? String {
                                updatedItem["updateCart.updatedShoppingCartItems." + stringKey] = value
                            }
                        }
                        
                        // handle dataFields if any
                        if let dataFields = eventItem[JsonKey.CommerceItem.dataFields] as? [AnyHashable: Any] {
                            for (key, value) in dataFields {
                                if key is String {
                                    updatedItem[key] = value
                                }
                            }
                        }
                        
                        for (key, value) in eventItem {
                            if (key as! String != JsonKey.Commerce.items && key as! String != JsonKey.CommerceItem.dataFields) {
                                if (key as! String == JsonKey.eventType) {
                                    updatedItem[key] = EventType.customEvent;
                                } else {
                                    updatedItem[key] = value
                                }
                            }
                        }
                        return updatedItem
                    }
                    processedEvents.append(contentsOf: itemsWithOtherProps)
                }
            }
        }
        return processedEvents
    }
    
    func extractKeys(jsonObject: [String: Any]) -> [String] {
        return Array(jsonObject.keys)
    }
    
    func extractKeys(dict: [AnyHashable: Any]) -> [String] {
        var keys: [String] = []
        for key in dict.keys {
            if let stringKey = key as? String {
                // If needed, use stringKey which is now guaranteed to be a String
                keys.append(stringKey)
            }
        }
        return keys
    }

    func evaluateTree(node: [String: Any], localEventData: [[AnyHashable: Any]]) -> Bool {
        if let searchQueries = node[JsonKey.CriteriaItem.searchQueries] as? [[String: Any]], let combinator = node[JsonKey.CriteriaItem.combinator] as? String {
            if combinator == JsonKey.CriteriaItem.Combinator.and {
                for query in searchQueries {
                    if !evaluateTree(node: query, localEventData: localEventData) {
                        return false  // If any subquery fails, return false
                    }
                }
                return true  // If all subqueries pass, return true
            } else if combinator == JsonKey.CriteriaItem.Combinator.or {
                for query in searchQueries {
                    if evaluateTree(node: query, localEventData: localEventData) {
                        return true  // If any subquery passes, return true
                    }
                }
                return false  // If all subqueries fail, return false
            }
        } else if let searchCombo = node[JsonKey.CriteriaItem.searchCombo] as? [String: Any] {
            return evaluateTree(node: searchCombo, localEventData: localEventData)
        } else if node[JsonKey.CriteriaItem.field] != nil {
            return evaluateField(node: node, localEventData: localEventData)
        }
        
        return false
    }

    func evaluateField(node: [String: Any], localEventData: [[AnyHashable: Any]]) -> Bool {
        do {
            return try evaluateFieldLogic(node: node, localEventData: localEventData)
        } catch {
            print("evaluateField JSON ERROR: \(error)")
        }
        return false
    }

    func evaluateFieldLogic(node: [String: Any], localEventData: [[AnyHashable: Any]]) throws -> Bool {
        var isEvaluateSuccess = false
        for eventData in localEventData {
            let localDataKeys = eventData.keys
            if node[JsonKey.eventType] as? String == eventData[JsonKey.eventType] as? String {
                if let field = node[JsonKey.CriteriaItem.field] as? String,
                   let comparatorType = node[JsonKey.CriteriaItem.comparatorType] as? String,
                   let fieldType = node[JsonKey.CriteriaItem.fieldType] as? String {
                    for key in localDataKeys {
                        if field == key as! String, let matchObj = eventData[key] {
                            if evaluateComparison(comparatorType: comparatorType, fieldType: fieldType, matchObj: matchObj, valueToCompare:  node[JsonKey.CriteriaItem.value] as? String) {
                                isEvaluateSuccess = true
                                break
                            }
                        }
                    }
                }
            }
        }
        return isEvaluateSuccess
    }

    func evaluateComparison(comparatorType: String, fieldType: String, matchObj: Any, valueToCompare: String?) -> Bool {
        guard var stringValue = valueToCompare else {
            return false
        }
        
        if let doubleValue = Double(stringValue) {
              stringValue = formattedDoubleValue(doubleValue)
        }
        
        switch comparatorType {
            case JsonKey.CriteriaItem.Comparator.Equals:
                return compareValueEquality(matchObj, stringValue)
            case JsonKey.CriteriaItem.Comparator.DoesNotEquals:
                return !compareValueEquality(matchObj, stringValue)
            case JsonKey.CriteriaItem.Comparator.IsSet:
                return !String(describing: matchObj).isEmpty
            case JsonKey.CriteriaItem.Comparator.GreaterThan:
                return compareNumericValues(matchObj, stringValue, compareOperator: >)
            case JsonKey.CriteriaItem.Comparator.LessThan:
                return compareNumericValues(matchObj, stringValue, compareOperator: <)
            case JsonKey.CriteriaItem.Comparator.GreaterThanOrEqualTo:
                return compareNumericValues(matchObj, stringValue, compareOperator: >=)
            case JsonKey.CriteriaItem.Comparator.LessThanOrEqualTo:
                return compareNumericValues(matchObj, stringValue, compareOperator: <=)
            case JsonKey.CriteriaItem.Comparator.Contains:
                return compareStringContains(matchObj, stringValue)
            case JsonKey.CriteriaItem.Comparator.StartsWith:
                return compareStringStartsWith(matchObj, stringValue)
            case JsonKey.CriteriaItem.Comparator.MatchesRegex:
                return compareWithRegex(matchObj as? String ?? "", pattern: stringValue)
            default:
                return false
        }
    }

    func formattedDoubleValue(_ d: Double) -> String {
        if d == Double(Int64(d)) {
            return String(format: "%lld", Int64(d))
        } else {
            return String(format: "%f", d).trimmingCharacters(in: CharacterSet(charactersIn: "0"))
        }
    }
    
    func compareValueEquality(_ sourceTo: Any, _ stringValue: String) -> Bool {
        switch (sourceTo, stringValue) {
            case (let doubleNumber as Double, let value): return doubleNumber == Double(value)
            case (let intNumber as Int, let value): return intNumber == Int(value)
            case (let longNumber as Int64, let value): return longNumber == Int64(value)
            case (let booleanValue as Bool, let value): return booleanValue == Bool(value)
            case (let stringTypeValue as String, let value): return stringTypeValue == value
            default: return false
        }
    }

    func compareNumericValues(_ sourceTo: Any, _ stringValue: String, compareOperator: (Double, Double) -> Bool) -> Bool {
        if let sourceNumber = Double(stringValue) {
            switch sourceTo {
            case let doubleNumber as Double:
                return compareOperator(doubleNumber, sourceNumber)
            case let intNumber as Int:
                return compareOperator(Double(intNumber), sourceNumber)
            case let longNumber as Int64:
                return compareOperator(Double(longNumber), sourceNumber)
            case let stringNumber as String:
                if let doubleFromString = Double(stringNumber) {
                    return compareOperator(doubleFromString, sourceNumber)
                } else {
                    return false // Handle the case where string cannot be converted to a Double
                }
            default:
                return false
            }
        } else {
            return false // Handle the case where stringValue cannot be converted to a Double
        }
    }
    
    func compareStringContains(_ sourceTo: Any, _ stringValue: String) -> Bool {
        if let stringTypeValue = sourceTo as? String {
            // sourceTo is a String
            return stringTypeValue.contains(stringValue)
        } else if let arrayTypeValue = sourceTo as? [String] {
            // sourceTo is an Array of String
            return arrayTypeValue.contains(stringValue)
        }
        return false
    }

    func compareStringStartsWith(_ sourceTo: Any, _ stringValue: String) -> Bool {
        guard let stringTypeValue = sourceTo as? String else { return false }
        return stringTypeValue.hasPrefix(stringValue)
    }
    
    func compareWithRegex(_ sourceTo: String, pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(sourceTo.startIndex..<sourceTo.endIndex, in: sourceTo)
            return regex.firstMatch(in: sourceTo, options: [], range: range) != nil
        } catch {
            print("Error creating regex: \(error)")
            return false
        }
    }
    
    private let anonymousCriteria: Data
    private let anonymousEvents: [[AnyHashable: Any]]
}
