import ArgumentParser
import Foundation
import Path

struct InitTool: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize a new SwiftGodot project"
    )

    @Argument(help: "The name of the project to initialize")
    var projectName: String

    func run() throws {
        let projectDirectory = Path.cwd.path / projectName
        guard let templateDirectory =
            Bundle.module.url(forResource: "ProjectTemplate", withExtension: nil, subdirectory: "Templates")
        else {
            fatalError("Could not find the project template directory")
        }

        let templatePath = Path(templateDirectory.path(percentEncoded: false))!
        do {
            try templatePath.copy(to: projectDirectory)
        } catch {
            fatalError("Could not copy the project template to the project directory: \(error)")
        }
        print("Copied the project template to the project directory")

        do {
            try replaceProjectName(in: projectDirectory, with: projectName)
        } catch {
            fatalError("Could not replace the project name in the files: \(error)")
        }
        print("Replaced the project name in the files")
    }

    /// Replaces every occurrence of "<#ProjectName#>" with the project name in the file's contents and names.
    /// - Parameters:
    ///  - path: The path of the file or directory to replace the project name in.
    /// - projectName: The name of the project.
    func replaceProjectName(in path: Path, with projectName: String) throws {
        switch path.type {
        case .file:
            let fileContents = try String(contentsOf: path)
            let newFileContents = fileContents.replacingOccurrences(of: "<#ProjectName#>", with: projectName)
            try newFileContents.write(to: path)

            let fileName = path.basename()
            let newFileName = fileName.replacingOccurrences(of: "<#ProjectName#>", with: projectName)
            try path.rename(to: newFileName)
        case .directory:
            for child in path.ls() {
                try replaceProjectName(in: child, with: projectName)
            }
            let directoryName = path.basename()
            let newDirectoryName = directoryName.replacingOccurrences(of: "<#ProjectName#>", with: projectName)
            try path.rename(to: newDirectoryName)
        default:
            break
        }
    }
}
