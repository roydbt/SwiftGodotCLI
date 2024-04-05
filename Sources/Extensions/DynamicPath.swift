import Path

extension DynamicPath {
    /// Converts the dynamic path to a static path.
    var path: Path {
        Path(self)
    }
}
