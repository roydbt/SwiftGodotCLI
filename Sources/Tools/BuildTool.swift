import ArgumentParser
import Foundation
import Path

struct BuildTool: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build the SwiftGodot project and copies the build's result into the bin folder"
    )

    @OptionGroup()
    var sharedOptions: SharedOptions

    func run() throws {
        let (swiftProjectDirectory, projectDirectory) =
            getSourceAndGodotDirectories(isRunningFromGodot: sharedOptions.isRunningFromGodot)

        let binDirectory = getAndValidateBinPath(from: projectDirectory)
        print("Found bin directory")

        let swiftProjectName = getProjectName(from: swiftProjectDirectory)!
        print("Found project name: \(swiftProjectName), now starting to build...")

        guard tryRunningBuildCommand(from: swiftProjectDirectory) else {
            fatalError("Could not build project")
        }

        let libSwiftGodotPath = swiftProjectDirectory / ".build" / "debug" / "libSwiftGodot.dylib"
        let libProjectNamePath = swiftProjectDirectory / ".build" / "debug" / "lib\(swiftProjectName).dylib"
        guard libSwiftGodotPath.exists,
              libProjectNamePath.exists
        else {
            fatalError("Could not find the compiled .dylib files")
        }
        print("Found the compiled .dylib files")

        do {
            try libSwiftGodotPath.copy(into: binDirectory, overwrite: true)
            try libProjectNamePath.copy(into: binDirectory, overwrite: true)
        } catch {
            fatalError("Could not copy the compiled .dylib files to the bin folder: \(error)")
        }
        print("Copied the compiled .dylib files to the bin folder")
    }

    func tryRunningBuildCommand(from directory: Path) -> Bool {
        let task = Process()
        task.arguments = ["-c", "swift build --configuration debug --package-path \"\(directory)\""]
        task.launchPath = "/bin/zsh"
        task.standardOutput = FileHandle.standardOutput
        task.standardError = FileHandle.standardError

        task.launch()
        task.waitUntilExit()

        return task.terminationStatus == 0
    }
}
