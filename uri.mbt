///|
fn index_from(text : String, wanted : Char, start : Int) -> Int? {
  for i = start; i < text.length(); i = i + 1 {
    if text.get_char(i) == Some(wanted) {
      return Some(i)
    }
  }
  None
}

///|
fn sequence_from(text : String, wanted : String, start : Int) -> Int? {
  if wanted.is_empty() {
    return Some(start)
  }
  for i = start; i + wanted.length() <= text.length(); i = i + 1 {
    if text[i:i + wanted.length()].to_owned() == wanted {
      return Some(i)
    }
  }
  None
}

///|
/// Extract the path and query used by robots matching. Fragments never take
/// part in HTTP requests and are removed.
pub fn path_from_uri(uri : String) -> String {
  let start = match sequence_from(uri, "://", 0) {
    Some(scheme_end) =>
      match index_from(uri, '/', scheme_end + 3) {
        Some(slash) => slash
        None =>
          match index_from(uri, '?', scheme_end + 3) {
            Some(query) => query
            None => uri.length()
          }
      }
    None => 0
  }
  let end = match index_from(uri, '#', start) {
    Some(fragment) => fragment
    None => uri.length()
  }
  let result = uri[start:end].to_owned()
  if result.is_empty() {
    "/"
  } else if result.has_prefix("?") {
    "/" + result
  } else if result.has_prefix("/") {
    result
  } else {
    "/" + result
  }
}
