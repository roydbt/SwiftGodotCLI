import Path
import SwiftParser
import SwiftSyntax

class ProjectNameFinder: SyntaxVisitor {
    var projectName: String?

    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        switch node.item {
        case let .decl(decl):
            if let decl = decl.as(VariableDeclSyntax.self) {
                walk(decl)
            }
            return .skipChildren
        default:
            return .skipChildren
        }
    }

    override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
        if node.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "package" {
            return .visitChildren
        }
        return .skipChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "Package" {
            return .visitChildren
        }
        return .skipChildren
    }

    override func visit(_ node: LabeledExprSyntax) -> SyntaxVisitorContinueKind {
        if node.label?.text == "name" {
            return .visitChildren
        }
        return .skipChildren
    }

    override func visit(_ node: StringSegmentSyntax) -> SyntaxVisitorContinueKind {
        projectName = node.content.text
        return .skipChildren
    }
}

/// Get the name of the project from the Swift project directory.
/// - Parameter swiftProjectDirectory: The path of the Swift project directory.
/// - Returns: The name of the project, or `nil` if it couldn't be inferred.
func getProjectName(from swiftProjectDirectory: Path) -> String? {
    do {
        let packageSwiftPath = getPackageSwiftPath(from: swiftProjectDirectory)
        let packageSwiftContent = try String(contentsOf: packageSwiftPath)
        let packageFile = Parser.parse(source: packageSwiftContent)
        let visitor = ProjectNameFinder(viewMode: .all)
        visitor.walk(packageFile)
        return visitor.projectName
    } catch {
        print("Error: \(error)")
        return nil
    }
}

/// Get and validate the name of the project from the Swift project directory.
/// - Parameter swiftProjectDirectory: The path of the Swift project directory.
/// - Returns: The name of the project.
func getAndValidateProjectName(from swiftProjectDirectory: Path) -> String {
    guard let projectName = getProjectName(from: swiftProjectDirectory) else {
        fatalError("Could not infer the project name")
    }
    return projectName
}

/// Get the path of the Godot project directory from the Swift project directory.
/// - Parameter swiftProjectDirectory: The path of the Swift project directory.
/// - Returns: The path of the Godot project directory.
func getGodotProjectPath(from swiftProjectDirectory: Path) -> Path {
    return swiftProjectDirectory.parent
}

/// Get the path of the source directory from the Godot project directory.
/// - Parameter godotProjectDirectory: The URL of the Godot project directory.
/// - Returns: The URL of the source directory.
func getSourcePath(from godotProjectDirectory: Path) -> Path {
    return godotProjectDirectory / "src"
}

/// Get the path of the bin directory from the Godot project directory.
/// - Parameter godotProjectDirectory: The path of the Godot project directory.
/// - Returns: The path of the bin directory.
func getAndValidateBinPath(from godotProjectDirectory: Path) -> Path {
    let binDirectory = godotProjectDirectory / "bin"
    guard binDirectory.exists else {
        fatalError("\(godotProjectDirectory) doesn't have a 'bin' folder in it")
    }
    return binDirectory
}

/// Get the source and Godot directories based on the current working directory.
/// - Parameter isRunningFromGodot: Whether the CLI is running from the Godot project directory or the Swift project directory.
/// - Returns: A tuple containing the source and Godot directories.
func getSourceAndGodotDirectories(isRunningFromGodot: Bool) -> (source: Path, godot: Path) {
    if isRunningFromGodot {
        let godotProjectDirectory = Path.cwd.path
        guard godotProjectDirectory.exists
        else {
            fatalError("\(godotProjectDirectory) is not a valid folder.")
        }
        return (getSourcePath(from: godotProjectDirectory), godotProjectDirectory)
    } else {
        let swiftProjectDirectory = Path.cwd.path
        guard swiftProjectDirectory.exists
        else {
            fatalError("\(swiftProjectDirectory) is not a valid folder.")
        }
        return (swiftProjectDirectory, getGodotProjectPath(from: swiftProjectDirectory))
    }
}

/// Get the path of the classes source directory from the Swift project directory.
/// - Parameter swiftProjectDirectory: The path of the Swift project directory.
/// - Returns: The path of the classes source directory.
func getClassesSourcePath(from swiftProjectDirectory: Path) -> Path? {
    guard let projectName = getProjectName(from: swiftProjectDirectory) else {
        return nil
    }
    return swiftProjectDirectory / "Sources" / projectName
}

/// Get and validate the path of the classes source directory from the Swift project directory.
/// - Parameter swiftProjectDirectory: The path of the Swift project directory.
/// - Returns: The path of the classes source directory.
func getAndValidateClassesSourcePath(from swiftProjectDirectory: Path) -> Path {
    guard let classesDirectory = getClassesSourcePath(from: swiftProjectDirectory) else {
        fatalError("Could not find the classes directory, probably because inability to infer the project name")
    }
    return classesDirectory
}

/// Get the path of the Package.swift file from the Swift project directory.
/// - Parameter swiftProjectDirectory: The path of the Swift project directory.
/// - Returns: The path of the Package.swift file.
func getPackageSwiftPath(from swiftProjectDirectory: Path) -> Path {
    return swiftProjectDirectory / "Package.swift"
}

/// Get the missing parent directories of a path, shallow to deep.
/// - Parameter path: The path to get the missing parent directories of.
/// - Returns: An array of the missing parent directories.
func getMissingParentDirectories(of path: Path) -> [Path] {
    var missingParentDirectories: [Path] = []
    var currentPath = path.parent
    while !currentPath.exists {
        missingParentDirectories.append(currentPath)
        currentPath = currentPath.parent
    }
    return missingParentDirectories.reversed()
}

/// Create the missing parent directories of a path, shallow to deep.
/// - Parameter path: The path to create the missing parent directories of.
func createMissingParentDirectories(of path: Path) {
    let missingParentDirectories = getMissingParentDirectories(of: path)
    for missingParentDirectory in missingParentDirectories {
        do {
            try missingParentDirectory.mkdir()
        } catch {
            fatalError("Could not create the directory \(missingParentDirectory)")
        }
    }
}
