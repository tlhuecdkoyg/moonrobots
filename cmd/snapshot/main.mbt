///|
fn usage() -> String {
  "Usage: moonrobots-snapshot <robots.txt> <product-token> <url-or-path> [batch-file]"
}

///|
fn main {
  match @env.args() {
    [_, source_path, agent, uri] =>
      try {
        let source = @fs.read_file_to_string(source_path)
        println(@robots.studio_snapshot(source, agent, uri, uri))
      } catch {
        _ => {
          println("error: unable to read the robots.txt source")
          @sys.exit(2)
        }
      }
    [_, source_path, agent, uri, batch_path] =>
      try {
        let source = @fs.read_file_to_string(source_path)
        let batch = @fs.read_file_to_string(batch_path)
        println(@robots.studio_snapshot(source, agent, uri, batch))
      } catch {
        _ => {
          println("error: unable to read a source or batch file")
          @sys.exit(2)
        }
      }
    _ => {
      println(usage())
      @sys.exit(2)
    }
  }
}
