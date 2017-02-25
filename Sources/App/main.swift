import Vapor
import VaporPostgreSQL

// Droplet
let drop = Droplet()

// Providers
try drop.addProvider(VaporPostgreSQL.Provider.self)

// Preparations
drop.preparations += Object.self
drop.preparations += ScheduleRecord.self

// Database
Object.database = drop.database
ScheduleRecord.database = drop.database

// Commands
drop.commands.append(ImportCommand(console: drop.console, droplet: drop))

// Run droplet
drop.run()
