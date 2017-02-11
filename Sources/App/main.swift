import Vapor

let drop = Droplet()

// Commands

drop.commands.append(FetchDataCommand(console: drop.console, droplet: drop))

drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}

drop.resource("posts", PostController())

drop.run()
