//
//  Date+Intervals.swift
//  Quetzalcoatl
//
//  Created by Igor Ranieri on 07.05.18.
//

import Foundation

extension Date {
    func daysSince(_ date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: self, to: date).day ?? 0
    }
}
