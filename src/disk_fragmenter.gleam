import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub type DefragError {
  NoNichesLeft
}

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
  |> defragment_disk()
  |> determine_checksum()
}

/// Logs a String with a prefix ////////////////////////////////////////////////
pub fn plog(input: String, prefix: String) {
  io.println(prefix <> input)
  input
}

//　Conversion //////////////////////////////////////////////////////////////////

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

// Defragmentation /////////////////////////////////////////////////////////////

pub fn defragment_disk(input: String) -> String {
  let graphemes = string.to_graphemes(input)
  // io.debug(graphemes)
  let defragged = defrag(graphemes)
  string.join(defragged, with: "")
}

fn defrag(graphemes: List(String)) -> List(String) {
  let first_space_block_pos = find_first_space_block(graphemes, 0)
  let last_file_block_pos = find_last_file_block(graphemes, 0, 0)
  // io.debug(first_space_block_pos)
  // io.debug(last_file_block_pos)
  case first_space_block_pos < last_file_block_pos {
    True -> {
      plog(string.join(graphemes, with: ""), "// DEFRAGGING: ")
      let second_half = list.split(graphemes, last_file_block_pos)
      let file_block_id = case list.first(second_half.1) {
        Ok(id) -> id
        Error(_) -> "-1"
      }
      let tmp_list =
        list.flatten([
          second_half.0,
          ["."],
          case list.rest(second_half.1) {
            Ok(l) -> l
            Error(_) -> []
          },
        ])
      let first_half = list.split(tmp_list, first_space_block_pos)
      let updated_graphemes =
        list.flatten([
          first_half.0,
          [file_block_id],
          case list.rest(first_half.1) {
            Ok(l) -> l
            Error(_) -> []
          },
        ])
      defrag(updated_graphemes)
    }
    False -> graphemes
  }
  // case find_intermittent_space(graphemes) {
  //   Ok(position) -> {
  //     plog(string.join(graphemes, with: ""), "// DEFRAGGING: ")
  //     let updated_graphemes = graphemes
  //   }
  //   Error(NoNichesLeft) -> {
  //     io.println("// OPERATION FINISHED")
  //     graphemes
  //   }
  // }
}

// fn find_intermittent_space(list: List(String)) -> Result(Int, DefragError) {
//   case list {
//     [a, ..rest] -> {
//       find_intermittent_space(rest)
//     }
//     [] -> Error(NoNichesLeft)
//   }
// }

fn find_first_space_block(list: List(String), index: Int) -> Int {
  case list {
    [current, ..rest] ->
      case current == "." {
        True -> index
        False -> find_first_space_block(rest, index + 1)
      }
    [] -> index
  }
}

fn find_last_file_block(list: List(String), index: Int, last_pos: Int) -> Int {
  case list {
    [current, ..rest] -> {
      let updated_last_pos = case current == "." {
        True -> last_pos
        False -> index
      }
      find_last_file_block(rest, index + 1, updated_last_pos)
    }
    [] -> last_pos
  }
}

// Checksum ////////////////////////////////////////////////////////////////////

pub fn determine_checksum(input: String) {
  plog(input, "// OUTPUT:     ")
  plog("69", "// CHECKSUM:   ")
}
