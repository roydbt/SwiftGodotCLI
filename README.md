# SwiftGodotCLI
A CLI tool to generate, manage, and build SwiftGodot projects.

## Usage
### Initialize a new project
For these examples, we will use "MyFirstProject" as the project name. In your terminal, navigate to the directory where you want to create your project and run the following command:
```shell
swiftgodot init MyFirstProject
```
This will create the following directory structure:
```
MyFirstProject/
├── icon.svg
├── icon.svg.import
├── project.godot
├── bin/
│   └── MyFirstProject.gdextension
└── src/
    ├── Package.swift
    └── Sources/
        └── MyFirstProject/
            └── MyFirstProject.swift
```
with everything already set up for you to start coding. The `icon.svg`, `icon.svg.import`, and `project.godot` files are the same as the ones generated by the Godot editor when creating a new project. The `bin/` directory will contain the compiled swift code. The `src/` directory is where you will write your Swift code.

### Add a new node class
In the `src/Sources/MyFirstProject/` directory, you can add a new node class file with the following content:
```shell
swiftgodot new class MyNewNode
```
This will create a new file `MyNewNode.swift` and register it in the `initSwiftExtension` macro in `MyFirstProject.swift`.

You can specify the path for the new file as follows:
```shell
swiftgodot new class Path/To/Node/MyNewNode
```

If you prefer to run the command from the root directory of your project, you can run the command with the `run-from-godot` flag:
```shell
swiftgodot new class MyNewNode --run-from-godot
```

### Build the project
When ready, you can build the project with the following command:
```shell
swiftgodot build
```
This will compile the Swift code and copy the generated `libSwiftGodot.dylib` and `libMyFirstProject.dylib` to the `bin/` directory.

## To Do
- [ ] Actually try the tool on a real project
- [ ] Reconsider the `create` command and are there any other types of files that can be created
- [ ] Maybe write some tests or something like that
- [ ] Add support for other platforms, currently only tested it on my local machine.
- [ ] Add a way to choose what class to extend when creating a new class
- [ ] Figure out how `Bundle.module` works and if it the best way to load the templates