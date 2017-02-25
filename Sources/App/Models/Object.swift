//
//  Object.swift
//  SumDUBot
//
//  Created by Yura Voevodin on 12.02.17.
//
//

import Vapor
import Fluent
import Foundation

final class Object: Model {

    // MARK: Properties

    var id: Node?
    var exists: Bool = false

    var serverID: Int
    var name: String
    var type: Int

    // MARK: - Initialization

    init(serverID: Int, name: String, type: Int) {
        self.serverID = serverID
        self.name = name
        self.type = type
    }

    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        serverID = try node.extract("serverid")
        name = try node.extract("name")
        type = try node.extract("type")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id": id,
            "serverid": serverID,
            "name": name,
            "type": type
            ])
    }
}

// MARK: - Preparation

extension Object: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(entity, closure: { data in
            data.id()
            data.int("serverid")
            data.string("name")
            data.int("type")
        })
    }

    static func revert(_ database: Database) throws {
        try database.delete(entity)
    }
}