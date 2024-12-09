import gleam/bool
import gleam/int
import gleam/io
import gleam/string

const title = "// Advent of Code 2024 - Day 9: Disk Fragmenter ////////////////////////////////"

const example = "2333133121414131402"

// const example = "12345"

pub fn main() {
  io.println(title)
  let input = example
  input
  |> plog("// READING:    ")
  |> convert_representation()
  |> plog("// CONVERTED:  ")
  |> defrag()
}

/// Logs a String with a prefix ////////////////////////////////////////////////
pub fn plog(input: String, prefix: String) {
  io.println(prefix <> input)
  input
}

pub fn convert_representation(input: String) -> String {
  expand(input, "", 0, True)
}

fn expand(input: String, accumulator: String, id: Int, is_file: Bool) -> String {
  // io.print(input <> ", ")
  // io.print(accumulator <> ", ")
  // io.debug(id)
  // io.debug(is_file)
  case string.pop_grapheme(input) {
    Ok(char) -> {
      let block_size = case int.base_parse(char.0, 10) {
        Ok(value) -> value
        Error(_) -> 0
      }
      expand(
        char.1,
        string.append(
          to: accumulator,
          suffix: expand_segment(id, block_size, is_file),
        ),
        case is_file {
          True -> id + 1
          False -> id
        },
        bool.negate(is_file),
      )
    }
    Error(Nil) -> accumulator
  }
}

fn expand_segment(id: Int, times: Int, is_file: Bool) -> String {
  case is_file {
    True -> string.repeat(int.to_string(id), times)
    False -> string.repeat(".", times)
  }
}

pub fn defrag(input: String) {
  let graphemes = string.to_graphemes(input)
  io.println("// DEFRAGGING: " <> string.join(graphemes, with: ""))
}
