import Foundation

class ParameterParser {
    
    func parseParameters(from components: [String], for command: (type: CommandType, action: CommandAction)) -> [CommandParameter] {
        var parameters: [CommandParameter] = []
        let requiredTypes = command.action.requiredParameterTypes
        
        guard components.count >= requiredTypes.count else {
            return parameters
        }
        
        for (index, parameterType) in requiredTypes.enumerated() {
            if index < components.count {
                let value = components[index]
                let parameter = createParameter(type: parameterType, value: value, index: index)
                parameters.append(parameter)
            }
        }
        
        if components.count > requiredTypes.count {
            let remainingComponents = Array(components[requiredTypes.count...])
            let additionalParameters = parseAdditionalParameters(remainingComponents)
            parameters.append(contentsOf: additionalParameters)
        }
        
        return parameters
    }
    
    private func createParameter(type: CommandParameterType, value: String, index: Int) -> CommandParameter {
        switch type {
        case .amount:
            return ParameterBuilder.amount(parseAmount(value))
        case .text:
            return ParameterBuilder.text(value)
        case .date:
            return ParameterBuilder.date(parseDate(value) ?? value)
        case .member:
            return ParameterBuilder.member(value)
        case .account:
            return ParameterBuilder.account(value)
        case .boolean:
            return ParameterBuilder.boolean(parseBoolean(value))
        case .number:
            return ParameterBuilder.number(parseNumber(value) ?? value)
        }
    }
    
    private func parseAmount(_ value: String) -> Decimal {
        let cleanedValue = value.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        
        return Decimal(string: cleanedValue) ?? 0
    }
    
    private func parseDate(_ value: String) -> Date? {
        let formatters = [
            DateFormatter.commandDate,
            DateFormatter.commandDateTime,
            createRelativeDateFormatter()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }
        
        return parseRelativeDate(value)
    }
    
    private func createRelativeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    private func parseRelativeDate(_ value: String) -> Date? {
        let lowercased = value.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        switch lowercased {
        case "today":
            return now
        case "tomorrow":
            return calendar.date(byAdding: .day, value: 1, to: now)
        case "yesterday":
            return calendar.date(byAdding: .day, value: -1, to: now)
        case "next week":
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        case "next month":
            return calendar.date(byAdding: .month, value: 1, to: now)
        default:
            if lowercased.contains("days") {
                let components = lowercased.components(separatedBy: " ")
                if let numberString = components.first,
                   let days = Int(numberString) {
                    return calendar.date(byAdding: .day, value: days, to: now)
                }
            }
            return nil
        }
    }
    
    private func parseBoolean(_ value: String) -> Bool {
        let lowercased = value.lowercased()
        return ["true", "yes", "1", "on", "enable", "enabled"].contains(lowercased)
    }
    
    private func parseNumber(_ value: String) -> Double? {
        return Double(value)
    }
    
    private func parseAdditionalParameters(_ components: [String]) -> [CommandParameter] {
        var parameters: [CommandParameter] = []
        var i = 0
        
        while i < components.count {
            let component = components[i]
            
            if component.hasPrefix("--") {
                let flagName = String(component.dropFirst(2))
                if i + 1 < components.count && !components[i + 1].hasPrefix("--") {
                    let value = components[i + 1]
                    let parameter = ParameterBuilder.text(value, name: flagName)
                    parameters.append(parameter)
                    i += 2
                } else {
                    let parameter = ParameterBuilder.boolean(true, name: flagName)
                    parameters.append(parameter)
                    i += 1
                }
            } else if component.hasPrefix("-") {
                let flagName = String(component.dropFirst(1))
                let parameter = ParameterBuilder.boolean(true, name: flagName)
                parameters.append(parameter)
                i += 1
            } else {
                let parameter = ParameterBuilder.text(component, name: "arg\(parameters.count)")
                parameters.append(parameter)
                i += 1
            }
        }
        
        return parameters
    }
    
    func parseQuotedString(_ input: String) -> [String] {
        var components: [String] = []
        var currentComponent = ""
        var insideQuotes = false
        var escapeNext = false
        
        for char in input {
            if escapeNext {
                currentComponent.append(char)
                escapeNext = false
                continue
            }
            
            switch char {
            case "\\":
                escapeNext = true
            case "\"", "'":
                insideQuotes.toggle()
            case " ", "\t", "\n":
                if insideQuotes {
                    currentComponent.append(char)
                } else if !currentComponent.isEmpty {
                    components.append(currentComponent)
                    currentComponent = ""
                }
            default:
                currentComponent.append(char)
            }
        }
        
        if !currentComponent.isEmpty {
            components.append(currentComponent)
        }
        
        return components
    }
}