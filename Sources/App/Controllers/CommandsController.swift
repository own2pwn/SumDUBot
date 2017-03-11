//
//  CommandsController.swift
//  SumDUBot
//
//  Created by Yura Voevodin on 04.03.17.
//
//

import Vapor
import HTTP

final class CommandsController {

    enum Command: String {
        case start = "/start"
        case firstStart = "/start start"
        case help = "/help"
        case info = "/info"
        case search = "/search"

        var response: String {
            let newLine = "\n\n"

            switch self {
            case .start, .firstStart:
                return "Вас вітає бот розкладу СумДУ! 😜" + newLine
                    + "Увага, бот знаходиться на стадії розробки, тому деякі команди можуть бути недоступні!" + newLine
                    + "Для зв'язку з розробником пишіть сюди - @voevodin_yura" + newLine
                    + "Ви можете здійснювати пошук за назвою групи, аудиторією або фамілією викладача." + newLine
                    + "Для перегляду доступних команд використовуйте /help"

            case .help:
                return "⚠️ Увага, бот знаходиться на стадії розробки, тому деякі команди можуть бути недоступні!" + newLine
                    + "/start - Початок роботи" + "\n"
                    + "/help - Допомога" + newLine
                    + "Для зв'язку з розробником пишіть сюди - @voevodin_yura"

            case .info:
                return "💡 Ідея розробки - https://github.com/appdev-academy/sumdu-ios" + newLine
                    + "📚 Бібліотеки: " + newLine
                    + "Vapor - A web framework and server for Swift that works on macOS and Ubuntu. (https://vapor.codes)" + newLine
                    + "Kanna - XML/HTML parser for Swift. (https://github.com/tid-kijyun/Kanna.git)" + newLine
                    + "PostgreSQL Provider for the Vapor web framework. (https://github.com/vapor/postgresql-provider)" + newLine
                    + "Delightful console output for Swift developers. (https://github.com/onevcat/Rainbow)" + newLine

            case .search:
                return "🔍 Введіть назву аудиторії, групи або ініціали викладача"
            }
        }
    }

    // MARK: - Actions

    func index(request: Request) throws -> ResponseRepresentable {
        // Message text from request JSON
        let message = (request.data["message", "text"]?.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var responseText = ""

        if let command = Command(rawValue: message) {
            // If it is a command
            responseText = command.response

        } else if message.hasPrefix("/info_") {
            // It isn't a command
            responseText = try findSchedule(for: message)

        } else {
            // Search objects
            let objects = try Object.findObjects(with: message)
            if objects.characters.count > 0 {
                responseText += objects
            }
        }

        // Generate response node
        // https://core.telegram.org/bots/api#sendmessage
        return try JSON(node: [
            "method": "sendMessage",
            "chat_id": request.data["message", "chat", "id"]?.int ?? 0,
            "text": responseText
            ])
    }
}

// MARK: - Helpers

extension CommandsController {

    fileprivate func findSchedule(for message: String) throws -> String {
        var response = "За вашим запитом нічого не знайдено, спробуйте інший"

        // Get ID of Object from message (/info_{id})
        let idString = message.substring(from: message.index(message.startIndex, offsetBy: 6))
        guard let id = Int(idString) else { return response }

        // Try to find records
        let records = try ScheduleRecord.findSchedule(by: id)
        if records.characters.count > 0 {
            response = records
        }
        return response
    }
}
