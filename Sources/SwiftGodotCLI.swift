import ArgumentParser
import Foundation

@main
struct SwiftGodotCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftgodot",
        abstract: "A utility for managing SwiftGodot projects",
        subcommands: [BuildTool.self, CreateTool.self, InitTool.self]
    )
}

struct SharedOptions: ParsableArguments {
    @Flag(name: [.customLong("run-from-godot")], help: "Run from the godot project directory")
    var isRunningFromGodot = false

    func validate() throws {
        let (swiftProjectDirectory, _) =
            getSourceAndGodotDirectories(isRunningFromGodot: isRunningFromGodot)

        guard swiftProjectDirectory.exists
        else {
            fatalError("Could not find the Swift project directory")
        }
    }
}
