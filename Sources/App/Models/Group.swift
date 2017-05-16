//
//  Group.swift
//  SumDUBot
//
//  Created by Yura Voevodin on 15.04.17.
//
//

import Vapor
import Fluent
import Foundation

final class Group: Typable {
    
    // MARK: Properties
    
    var id: Node?
    var exists: Bool = false
    
    var serverID: Int
    var name: String
    var updatedAt: String
    var lowercaseName: String
    
    // MARK: Initialization
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        serverID = try node.extract(TypableFields.serverID.name)
        name = try node.extract(TypableFields.name.name)
        updatedAt = try node.extract(TypableFields.updatedAt.name)
        lowercaseName = try node.extract(TypableFields.lowercaseName.name)
    }
    
    init?(array: [String : Any]) {
        guard let serverID = array[TypableFields.serverID.name] as? Int else { return nil }
        self.serverID = serverID
        
        guard let name = array[TypableFields.name.name] as? String else { return nil }
        self.name = name
        
        guard let updatedAt = array[TypableFields.updatedAt.name] as? String else { return nil }
        self.updatedAt = updatedAt
        
        guard let lowercaseName = array[TypableFields.lowercaseName.name] as? String else { return nil }
        self.lowercaseName = lowercaseName
    }
    
    // MARK: - Node
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            TypableFields.serverID.name: serverID,
            TypableFields.name.name: name,
            TypableFields.updatedAt.name: updatedAt,
            TypableFields.lowercaseName.name: lowercaseName
            ]
        )
    }
}

// MARK: - Helpers

extension Group {
    
    static func find(by name: String) throws -> String {
        guard name.characters.count > 2 else { return "" }
        var response = ""
        let groups = try Group.query().filter(TypableFields.lowercaseName.name, contains: name.lowercased()).all()
        for group in groups {
            response += group.name + " - " + ObjectType.group.prefix + "\(group.serverID)" + newLine
        }
        guard response.characters.count > 0 else { return "" }
        return twoLines + "👥 Групи:" + twoLines + response
    }
    
    static func show(for message: String, chat: [String : Polymorphic]?) throws -> String {
        // Get ID of group from message (/group_{id})
        let idString = message.substring(from: message.index(message.startIndex, offsetBy: 7))
        guard let id = Int(idString) else { return "" }
        
        // Find records for groups
        guard var group = try Group.query().filter(TypableFields.serverID.name, id).first() else { return "" }
        let currentHour = Date().dateWithHour
        if group.updatedAt != currentHour {
            // Try to delete old records
            try group.records().delete()
            
            // Try to import schedule
            try ScheduleImportManager.importSchedule(for: .group, id: group.serverID)
            
            // Update date in object
            group.updatedAt = currentHour
            try group.save()
        }
        
        // Register request for user
        if let chat = chat, let id = group.id {
            BotUser.registerRequest(for: chat, objectID: id, type: .group)
        }
        
        let records = try group.records()
            .sort("date", .ascending)
            .sort("pair_name", .ascending)
            .all()
        
        // Formatting a response
        var response = Record.prepareResponse(for: records)
        response += twoLines +  "👥 Група - " + group.name
        return response
    }
}

// MARK: - Relationships

extension Group {
    func records() throws -> Children<Record> {
        return children()
    }
}

// MARK: - Preparation

extension Group: Preparation {
    
    static func prepare(_ database: Database) throws {
        try database.create(entity, closure: { object in
            object.id()
            object.int(TypableFields.serverID.name)
            object.string(TypableFields.name.name)
            object.string(TypableFields.updatedAt.name)
            object.string(TypableFields.lowercaseName.name)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(entity)
    }
}