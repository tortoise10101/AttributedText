//
// AttributedStringProtocol++.swift
//

import Foundation
import RegexBuilder

extension AttributedStringProtocol {
    func range(_ pattern: String, options: String.CompareOptions? = nil) -> Range<AttributedString.Index>? {
        let options = options?.union(.regularExpression) ?? .regularExpression
        return self.range(of: pattern, options: options)
    }
    
    func ranges(_ pattern: String, options: String.CompareOptions? = nil) -> [Range<AttributedString.Index>] {
        guard let range = range(pattern, options: options) else {
            return []
        }
        
        let remaining = self[range.upperBound...]
        return [range] + remaining.ranges(pattern, options: options)
    }
}

extension AttributedString {
    func addingURL(container: AttributeContainer) -> Self {
        var attributedString = self
        
        let pattern = "(http://|https://){1}[\\w\\.\\-/:]+"
        let regex = try! NSRegularExpression(pattern: pattern)
        let text = String(attributedString.characters)
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for range in matches {
            let stringValue = String(text[Range(range.range, in: text)!])
            
            let ranges = attributedString.ranges(stringValue)
            
            for range in ranges {
                var container = container
                if let url = URL(string: stringValue) {
                    container.link = url
                }
                attributedString[range].setAttributes(container)
            }
        }
        
        return attributedString
    }
    
    func addingPrefixLink(prefixes: [AttributedPrefix]) -> Self {
        var attributedString = self
        
        for item in prefixes {
            let regex = try! NSRegularExpression(pattern: "\(item.prefix)[^ 　\n\t]*")
            
            let text = String(attributedString.characters)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for range in matches {
                let stringValue = String(text[Range(range.range, in: text)!])
                guard
                    item.prefix.startIndex <= stringValue.endIndex
                        && item.prefix.endIndex <= stringValue.endIndex
                else { continue }
                
                let ranges = attributedString.ranges(stringValue)
                
                for range in ranges {
                    var url = AttributedText.attributedURL
                    //url.append(queryItems: [.init(name: "query", value: stringValue)])
                    url.appendQueryItem(name: "query", value: stringValue)
                    
                    var container = item.container
                    container.link = url
                    
                    attributedString[range].setAttributes(container)
                }
            }
        }
        
        return attributedString
    }
}

extension URL {

    mutating func appendQueryItem(name: String, value: String?) {

        guard var urlComponents = URLComponents(string: absoluteString) else { return }

        // Create array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []

        // Create query item
        let queryItem = URLQueryItem(name: name, value: value)

        // Append the new query item in the existing query items array
        queryItems.append(queryItem)

        // Append updated query items array in the url component object
        urlComponents.queryItems = queryItems

        // Returns the url from new url components
        self = urlComponents.url!
    }
}
