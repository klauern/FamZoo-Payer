import Foundation

class AbbreviationExpander {
    
    func expandType(_ input: String) -> CommandType? {
        return CommandType.from(input.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func expandAction(_ input: String) -> CommandAction? {
        return CommandAction.from(input.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    func expandCommand(_ input: String) -> (type: CommandType?, action: CommandAction?) {
        let components = tokenize(input)
        guard components.count >= 2 else {
            return (nil, nil)
        }
        
        let type = expandType(components[0])
        let action = expandAction(components[1])
        
        return (type, action)
    }
    
    private func tokenize(_ input: String) -> [String] {
        return input.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }
    
    func getAllAbbreviations() -> [String: String] {
        var abbreviations: [String: String] = [:]
        
        for type in CommandType.allCases {
            for abbreviation in type.abbreviations {
                abbreviations[abbreviation] = type.rawValue
            }
        }
        
        for action in CommandAction.allCases {
            for abbreviation in action.abbreviations {
                abbreviations[abbreviation] = action.rawValue
            }
        }
        
        return abbreviations
    }
    
    func suggestionsFor(_ input: String) -> [String] {
        let lowercased = input.lowercased()
        var suggestions: [String] = []
        
        for type in CommandType.allCases {
            if type.rawValue.hasPrefix(lowercased) {
                suggestions.append(type.rawValue)
            }
            for abbreviation in type.abbreviations {
                if abbreviation.hasPrefix(lowercased) {
                    suggestions.append(abbreviation)
                }
            }
        }
        
        for action in CommandAction.allCases {
            if action.rawValue.hasPrefix(lowercased) {
                suggestions.append(action.rawValue)
            }
            for abbreviation in action.abbreviations {
                if abbreviation.hasPrefix(lowercased) {
                    suggestions.append(abbreviation)
                }
            }
        }
        
        return Array(Set(suggestions)).sorted()
    }
}