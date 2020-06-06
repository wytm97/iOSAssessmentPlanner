//
//  CalendarManager.swift
//  Assessment Planner
//
//  Created by Yasin on 6/6/20.
//  Copyright © 2020 Yasin. All rights reserved.
//

import Foundation
import EventKit

public class CalendarManager {
    
    static let shared = CalendarManager()
    
    // EKEventStore object requires a relatively large amount of time
    // to initialize and release. It is very inefficient to initialize
    // and release a separate event store for each event-related task.
    // So, we create one single instance in our global app state.
    
    var eventStore: EKEventStore!
    
    private init() {
        self.eventStore = EKEventStore()
    }
    
    // MARK: Permissions & Authorization
    
    private func getAuthorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: EKEntityType.event)
    }
    
    private func requestAccess(completion: @escaping EKEventStoreRequestAccessCompletionHandler) -> Void {
        eventStore.requestAccess(to: EKEntityType.event) { (accessGranted: Bool, error: Error?) in
            completion(accessGranted, error)
        }
    }
    
    // MARK: API methods
    
    func doCheckPermissions(completion: @escaping CalendarManagerResponseCallback) -> Void {
        
        let authStatus = getAuthorizationStatus()
        
        if authStatus == .authorized {
            // Safe to perform operations
            completion(.success)
        } else if authStatus == .notDetermined {
            // Request access again
            requestAccess { (granted, error) in
                if granted {
                    completion(.success)
                } else {
                    // show a alert and notify the user in the view
                    completion(.error(.calendarAccessDeniedOrRestricted))
                }
            }
        } else if authStatus == .denied || authStatus == .restricted {
            completion(.error(.calendarAccessDeniedOrRestricted))
        } else { // @unknown default
            completion(.error(.generic(message: "@unknown error")))
        }
        
    }
    
    func createEvent(_ event: CalendarEvent, completion: @escaping CalendarManagerResponseCallback) -> Void {
        
        let newEvent = EKEvent(eventStore: self.eventStore)
        newEvent.calendar = self.eventStore.defaultCalendarForNewEvents
        newEvent.title = event.title
        newEvent.startDate = event.startDate
        newEvent.endDate = event.endDate
        newEvent.notes = event.notes
        newEvent.isAllDay = false
        
        if event.alarmOffset != .none {
            if event.alarmOffset == .atTheTimeOfEvent {
                /// set absolute date as the start date.
                newEvent.addAlarm(EKAlarm(absoluteDate: newEvent.startDate))
                print("created alarm with a absolute date of \(newEvent.startDate.description)")
            } else {
                /// user requested custom event reminder
                let offset: Double = Double(event.alarmOffset.time() * -1) * 60 // to seconds
                newEvent.addAlarm(EKAlarm(relativeOffset: TimeInterval(offset)))
                print("created alarm with a relativeOffset of \(offset)")
            }
        }
        
        if !self.eventAlreadyExists(newEvent) {
            do {
                try self.eventStore!.save(newEvent, span: .thisEvent)
                let identifier = newEvent.eventIdentifier ?? nil
                completion(.created(identifier: identifier))
            } catch let error {
                // Error while trying to create event in calendar
                completion(.error(.eventNotAddedToCalendar(message: error.localizedDescription)))
            }
        } else {
            completion(.error(.eventAlreadyExistsInCalendar))
        }
        
    }
    
    func updateEvent(eventIdentifier: String, updatedEvent: CalendarEvent, completion: @escaping CalendarManagerResponseCallback) -> Void {
        
        let existingEvent: EKEvent? = eventStore.event(withIdentifier: eventIdentifier)
        
        if existingEvent == nil {
            self.createEvent(updatedEvent, completion: completion)
            // completion(.error(.noSuchEventMatchingTheIdentifier))
        } else {
            
            existingEvent!.title = updatedEvent.title
            existingEvent!.startDate = updatedEvent.startDate
            existingEvent!.endDate = updatedEvent.endDate
            existingEvent!.notes = updatedEvent.notes
            
            if updatedEvent.alarmOffset == .none { // remove all the alarms
                self.deleteEventAlarms(existingEvent!)
            } else {
                self.deleteEventAlarms(existingEvent!)
                if updatedEvent.alarmOffset == .atTheTimeOfEvent {
                    /// set absolute date as the start date.
                    existingEvent!.addAlarm(EKAlarm(absoluteDate: updatedEvent.startDate))
                    print("created alarm with a absolute date of \(updatedEvent.startDate.description)")
                } else {
                    /// user requested custom event reminder
                    let offset: Double = Double(updatedEvent.alarmOffset.time() * -1) * 60 // to seconds
                    existingEvent!.addAlarm(EKAlarm(relativeOffset: TimeInterval(offset)))
                    print("created alarm with a relativeOffset of \(offset)")
                }
            }
            
            do {
                try self.eventStore!.save(existingEvent!, span: .thisEvent, commit: true)
                completion(.updated)
            } catch {
                completion(.error(.eventFailedToUpdate))
            }
        }
        
    }
    
    func deleteEvent(_ eventIdentifier: String, completion: @escaping CalendarManagerResponseCallback) -> Void {
        
        let event = eventStore.event(withIdentifier: eventIdentifier)
        
        if event == nil {
            completion(.error(.noSuchEventMatchingTheIdentifier))
        } else {
            do {
                try self.eventStore.remove(event!, span: .thisEvent)
                completion(.deleted)
            } catch let error {
                completion(.error(.generic(message: error.localizedDescription)))
            }
        }
        
    }
    
    func deleteCalendarEventAsync(id: String) -> Void {
        if id != "" /* Redundant task if it's an empty string */ {
            self.doCheckPermissions { (response: CalendarManagerResponse) in
                if response == .success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.deleteEvent(id) { (res) in
                            if res == .deleted {
                                print("removed calendar event")
                            } else if res == .error(.noSuchEventMatchingTheIdentifier) {
                                print("no such event found to remove from the calendar")
                            } else if case .error(.generic(let message)) = res {
                                print("generic error", message)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Utility functions
    
    private func eventAlreadyExists(_ eventToAdd: EKEvent) -> Bool {
        
        let predicate = self.eventStore.predicateForEvents(
            withStart: eventToAdd.startDate,
            end: eventToAdd.endDate,
            calendars: nil
        )
        
        let existingEvents = eventStore.events(matching: predicate)
        let eventAlreadyExists = existingEvents.contains { (event) -> Bool in
            return eventToAdd.title == event.title &&
                event.startDate == eventToAdd.startDate &&
                event.notes == eventToAdd.notes &&
                event.alarms?.count == eventToAdd.alarms?.count &&
                event.endDate == eventToAdd.endDate
        }
        
        return eventAlreadyExists
        
    }
    
    private func deleteEventAlarms(_ event: EKEvent) -> Void {
        if let alarms = event.alarms { // check if alarms is non nil
            if alarms.count > 0 {
                for a in alarms {
                    event.removeAlarm(a)
                }
            }
        }
    }
    
}

struct CalendarEvent {
    var title: String
    var startDate: Date
    var endDate: Date
    var notes: String // User added custom notes
    var alarmOffset: AlarmOffset // Autoreleased alarm with a relative trigger time (minutes)
}

enum CalendarManagerResponse: Equatable {
    case created(identifier: String?) // Returns identifier
    case updated
    case deleted
    case success
    case error(EventKitFrameworkException)
}

enum EventKitFrameworkException: Error, Equatable {
    case eventAlreadyExistsInCalendar
    case eventNotAddedToCalendar(message: String)
    case eventFailedToUpdate
    case calendarAccessDeniedOrRestricted
    case noSuchEventMatchingTheIdentifier
    case generic(message: String)
}

typealias CalendarManagerResponseCallback = (_ response: CalendarManagerResponse) -> Void

enum AlarmOffset: String, CaseIterable, Equatable {
    
    case none = "-"
    case atTheTimeOfEvent = "@"
    case fiveMinutesBefore = "5M"
    case tenMinutesBefore = "10M"
    case fifteenMinutesBefore = "15M"
    case thirtyMinutesBefore = "30M"
    case oneHourBefore = "1H"
    case twoHoursBefore = "2H"
    case oneDayBefore = "1D"
    case twoDaysBefore = "2D"
    case oneWeekBefore = "1W"
    
    static func rawValues() -> [String] {
        return [
            none.rawValue,
            atTheTimeOfEvent.rawValue,
            fiveMinutesBefore.rawValue,
            tenMinutesBefore.rawValue,
            fifteenMinutesBefore.rawValue,
            thirtyMinutesBefore.rawValue,
            oneHourBefore.rawValue,
            twoHoursBefore.rawValue,
            oneDayBefore.rawValue,
            twoDaysBefore.rawValue,
            oneWeekBefore.rawValue
        ]
    }
    
    static func fromRawValue(str: String) -> AlarmOffset {
        switch str {
        case AlarmOffset.none.rawValue:
            return .none
        case AlarmOffset.atTheTimeOfEvent.rawValue:
            return .atTheTimeOfEvent
        case AlarmOffset.fiveMinutesBefore.rawValue:
            return .fiveMinutesBefore
        case AlarmOffset.tenMinutesBefore.rawValue:
            return .tenMinutesBefore
        case AlarmOffset.fifteenMinutesBefore.rawValue:
            return .fifteenMinutesBefore
        case AlarmOffset.thirtyMinutesBefore.rawValue:
            return .thirtyMinutesBefore
        case AlarmOffset.oneHourBefore.rawValue:
            return .oneHourBefore
        case AlarmOffset.twoHoursBefore.rawValue:
            return .twoHoursBefore
        case AlarmOffset.oneDayBefore.rawValue:
            return .oneDayBefore
        case AlarmOffset.twoDaysBefore.rawValue:
            return .twoDaysBefore
        case AlarmOffset.oneWeekBefore.rawValue:
            return .oneWeekBefore
        default:
            return .none
        }
    }
    
    func time() -> Int {
        switch self {
        case .none:
            return 0
        case .atTheTimeOfEvent:
            return 0
        case .fiveMinutesBefore:
            return 5
        case .tenMinutesBefore:
            return 10
        case .fifteenMinutesBefore:
            return 15
        case .thirtyMinutesBefore:
            return 30
        case .oneHourBefore:
            return 60
        case .twoHoursBefore:
            return 60 * 2
        case .oneDayBefore:
            return 60 * 24
        case .twoDaysBefore:
            return 60 * 24 * 2
        case .oneWeekBefore:
            return 60 * 24 * 7
        }
    }
    
    func textualRepresentation() -> String {
        switch self {
        case .none:
            return "None"
        case .atTheTimeOfEvent:
            return "At the Time of Event"
        case .fiveMinutesBefore:
            return "5 Minutes Before"
        case .tenMinutesBefore:
            return "10 Minutes Before"
        case .fifteenMinutesBefore:
            return "15 Minutes Before"
        case .thirtyMinutesBefore:
            return "30 Minutes Before"
        case .oneHourBefore:
            return "1 Hour Before"
        case .twoHoursBefore:
            return "2 Hours Before"
        case .oneDayBefore:
            return "1 Day Before"
        case .twoDaysBefore:
            return "2 Days Before"
        case .oneWeekBefore:
            return "1 Week Before"
        }
    }
    
}
