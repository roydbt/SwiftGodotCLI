import ArgumentParser
import Foundation
import Path
import SwiftParser
import SwiftSyntax

struct CreateTool: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Generate some pre-made files for a new SwiftGodot project",
        subcommands: [CreateClassTool.self]
    )

    struct CreateClassTool: ParsableCommand {
        static var configuration = CommandConfiguration(
            commandName: "class",
            abstract: "Generate a new SwiftGodot class"
        )

        @Argument(help: "The name of the class to create")
        var classPath: String

        @OptionGroup
        var sharedOptions: SharedOptions

        func run() throws {
            guard let className = classPath.components(separatedBy: "/").last?.components(separatedBy: ".").first
            else {
                fatalError("Could not infer the class name")
            }
            let (swiftProjectDirectory, _) =
                getSourceAndGodotDirectories(isRunningFromGodot: sharedOptions.isRunningFromGodot)
            let classesDirectory = getAndValidateClassesSourcePath(from: swiftProjectDirectory)
            let projectName = getAndValidateProjectName(from: swiftProjectDirectory)

            let godotInitFilePath = classesDirectory / "\(projectName).swift"
            guard godotInitFilePath.exists
            else {
                fatalError("Could not find the GodotInit.swift file")
            }
            guard let godotInitFileContents = try? String(contentsOf: godotInitFilePath)
            else {
                fatalError("Could not read the GodotInit.swift file")
            }

            // TODO: migrade this too to Path.swift
            guard let templateFilePath =
                Bundle.module.url(forResource: "ClassTemplate", withExtension: "swift", subdirectory: "Templates")
            else {
                fatalError("Could not find the class template file")
            }

            print("Creating class \(className)")

            let classTemplate = try String(contentsOf: templateFilePath)
            let classContent = classTemplate.replacingOccurrences(of: "<#ClassName#>", with: className)
            let classPath = classesDirectory / classPath.appending(".swift")
            do {
                var classPathParents = classPath.parent
                while !classPathParents.exists {
                    try classPathParents.mkdir()
                    classPathParents = classPathParents.parent
                }
                try classPath.touch()
                try classContent.write(to: classPath, atomically: true, encoding: .utf8)
            } catch {
                fatalError("Could not create the class file: \(error)")
            }
            print("Created class \(className) at \(classPath)")

            let godotInitFile = Parser.parse(source: godotInitFileContents)
            let rewriter = AddClassNameToGodotInit(className: className)
            let newGodotInitFile = rewriter.visit(godotInitFile)
            do {
                try newGodotInitFile.description.write(to: godotInitFilePath, atomically: true, encoding: .utf8)
            } catch {
                fatalError("Could not write to the GodotInit.swift file: \(error)")
            }
            print("Added class \(className) to \(projectName).swift")
        }

        class AddClassNameToGodotInit: SyntaxRewriter {
            let className: String

            init(className: String) {
                self.className = className
            }

            override func visit(_ typesArray: ArrayElementListSyntax) -> ArrayElementListSyntax {
                guard let labelParent = typesArray.parent?.parent?.as(LabeledExprSyntax.self),
                      labelParent.label?.text == "types",
                      let parentMacro = labelParent.parent?.parent?.as(MacroExpansionExprSyntax.self),
                      parentMacro.macroName.text == "initSwiftExtension"
                else {
                    return typesArray
                }
                let commaSeperator = TokenSyntax(.comma, trailingTrivia: .space, presence: .present)
                var newTypesArray = typesArray

                if var lastElement = typesArray.last {
                    let index = typesArray.index(of: lastElement)!
                    lastElement.trailingComma = commaSeperator
                    newTypesArray = typesArray.with(\.[index], lastElement)
                }

                let newType = ArrayElementSyntax(
                    expression: MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: TokenSyntax(.identifier(className), presence: .present)),
                        declName: DeclReferenceExprSyntax(baseName: TokenSyntax(.keyword(.self), presence: .present))
                    ))

                newTypesArray.append(newType)

                return newTypesArray
            }
        }
    }
}
