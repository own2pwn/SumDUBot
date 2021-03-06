//
//  Teacher.swift
//  SumDUBot
//
//  Created by Yura Voevodin on 15.04.17.
//
//

import Vapor
import FluentProvider

final class Teacher: ListObject {
    let storage = Storage()
    
    // MARK: Properties
    
    var serverID: Int
    var name: String
    var updatedAt: String
    var lowercaseName: String
    
    // MARK: Fluent Serialization
    
    /// Initializes the ListObject from the
    /// database row
    required init(row: Row) throws {
        serverID = try row.get(Field.serverID.name)
        name = try row.get(Field.name.name)
        updatedAt = try row.get(Field.updatedAt.name)
        lowercaseName = try row.get(Field.lowercaseName.name)
    }
    
    /// Serializes the ListObject to the database
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Field.serverID.name, serverID)
        try row.set(Field.name.name, name)
        try row.set(Field.updatedAt.name, updatedAt)
        try row.set(Field.lowercaseName.name, lowercaseName)
        return row
    }
}

// MARK: - Relationships

extension Teacher {
    var records: Children<Teacher, Record> {
        return children()
    }
}

// MARK: - Preparation

extension Teacher: Preparation {
    
    static func prepare(_ database: Database) throws {
        try database.create(self, closure: { object in
            object.id()
            object.int(Field.serverID.name)
            object.string(Field.name.name)
            object.string(Field.updatedAt.name)
            object.string(Field.lowercaseName.name)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: - Helpers

extension Teacher {
    
    static func find(by name: String) throws -> String {
        var response = ""
        guard name.characters.count > 3 else { return response }
        
        let teachers = try Teacher.makeQuery().filter(Field.lowercaseName.name, .contains, name.lowercased()).all()
        for teacher in teachers {
            response += teacher.name + " - /teacher_\(teacher.serverID)" + newLine
        }
        guard !response.isEmpty else { return "" }
        return twoLines + "👔 Викладачі:" + twoLines + response
    }
    
    static func find(by name: String) throws -> [Button] {
        guard name.characters.count > 3 else { return [] }
        var buttons: [Button] = []
        let teachers = try Teacher.makeQuery().filter(Field.lowercaseName.name, .contains, name.lowercased()).all()
        for teacher in teachers {
            let payload = ObjectType.teacher.prefix + "\(teacher.serverID)"
            let auditoriumButton = try Button(type: .postback, title: teacher.name, payload: payload)
            buttons.append(auditoriumButton)
        }
        return buttons
    }
    
    static func show(for message: String, chat: [String : Node]? = nil, client: ClientFactoryProtocol) throws -> [String] {
        // Get ID of teacher from message (/teacher_{id})
        let idString = message.substring(from: message.index(message.startIndex, offsetBy: 9))
        guard let id = Int(idString) else { return [] }
        
        // Find records for teachers
        guard let teacher = try Teacher.makeQuery().filter(Field.serverID.name, id).first() else { return [] }
        let currentHour = Date().dateWithHour
        if teacher.updatedAt != currentHour {
            // Try to delete old records
            try teacher.records.delete()
            
            // Try to import schedule
            try ScheduleImportManager.importSchedule(for: .teacher, id: teacher.serverID, client: client)
            
            // Update date in object
            teacher.updatedAt = currentHour
            try teacher.save()
        }
        
        // Register request for user
        if let chat = chat, let id = teacher.id {
            BotUser.registerRequest(for: chat, objectID: id, type: .teacher)
        }
        
        let records = try teacher.records
            .sort("date", .ascending)
            .sort("pair_name", .ascending)
            .all()
        
        return Record.prepareResponse(for: records)
    }
}
