//
//  LocalizationMap.swift
//
//  Created by Sébastien Duperron on 14/05/2016.
//  Copyright © 2016 Sébastien Duperron
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

/**
 This describes the type of the Localization.
 This is necessary because of the differences of content of string values like string parameters.
 `%s` is for Java string on Android while the equivalent is `%@` on iOS.
 */
enum LocalizationType {
    case android
    case ios
}

struct LocalizationMap {
    fileprivate(set) var type: LocalizationType
    fileprivate(set) var localizations = [String:LocalizationItem]()

    init(type: LocalizationType) {
        self.type = type
    }

    init(type: LocalizationType, dictionary: [String:String]) {
        self.init(type: type)
        dictionary.forEach { localizations[$0] = .string(value: $1) }
    }

    init(type: LocalizationType, localizationsDictionary: [String:LocalizationItem]) {
        self.init(type: type)
        localizations = localizationsDictionary
    }

    subscript(key: String) -> LocalizationItem? {
        get {
            return localizations[key]
        }

        set(newValue) {
            guard let newValue = newValue else {
                localizations.removeValue(forKey: key)
                return
            }
            localizations[key] = newValue
        }
    }

    var keys: [String] {
        return Array(localizations.keys)
    }

    var count: Int {
        return localizations.count
    }
}

extension LocalizationMap: Equatable {}

func == (left: LocalizationMap, right: LocalizationMap) -> Bool {
    return left.type == right.type
        && left.localizations == right.localizations
}

extension LocalizationMap {
    func convertedLocalization(to type: LocalizationType) -> LocalizationMap {
        if type == self.type {
            return self
        }
        switch type {
        case .android:
            fatalError("Unsupported convertion \(self.type) -> \(type) (yet)")
        case .ios:
            guard let stringParameterReplacer = RegexReplacer(pattern: "%([0-9]+\\$)?s", replaceTemplate: "%$1@") else {
                fatalError("Could not initialize replacer!")
            }

            return LocalizationMap(
                type: .ios,
                localizationsDictionary: convert(localizations, using: stringParameterReplacer))
        }
    }

    fileprivate func convert(_ localizations: [String:LocalizationItem],
                         using replacer: RegexReplacer) -> [String:LocalizationItem] {
        var iOSLocalizations = [String:LocalizationItem]()
        localizations.forEach { (key, item) in
            let convertedItem: LocalizationItem
            switch item {
            case .string(let value):
                convertedItem = .string(value: replacer.replacingMatches(in: value))
            case .plurals(let plurals):
                let convertedPlurals = convert(plurals, using: replacer)
                convertedItem = .plurals(values: convertedPlurals)
            }
            iOSLocalizations[key] = convertedItem
        }
        return iOSLocalizations
    }

    fileprivate func convert(_ plurals: [PluralType:String], using replacer: RegexReplacer) -> [PluralType:String] {
        var convertedPlurals = [PluralType:String]()
        plurals.forEach { (type, value) in
            convertedPlurals[type] = replacer.replacingMatches(in: value)
        }
        return convertedPlurals
    }
}
