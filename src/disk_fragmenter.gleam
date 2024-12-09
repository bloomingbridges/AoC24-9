import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

const title = "// Advent of Code 2024 - Day 9: Disk Fragmenter ////////////////////////////////"

const example = "2333133121414131402"

// const example = "12345"

pub fn main() {
  io.println(title)
  let input = case simplifile.read("./src/input.txt") {
    Ok(file) -> file
    Error(error) -> {
      io.debug(error)
      example
    }
  }
  io.println("// READING:    " <> input)
  let converted_input = convert_representation(input)
  converted_input
  |> plog("// CONVERTED:  ")
  |> defragment_disk()
  |> plog("// DEFRAGGED:  ")
  |> determine_checksum()
}

/// Logs a List(String) with a given String prefix /////////////////////////////
pub fn plog(input: List(String), prefix: String) -> List(String) {
  io.println(prefix <> string.join(input, ""))
  input
}

//　Conversion //////////////////////////////////////////////////////////////////

pub fn convert_representation(input: String) -> List(String) {
  expand(string.to_graphemes(input), [], 0, True)
}

fn expand(
  input: List(String),
  accumulator: List(String),
  id: Int,
  is_file: Bool,
) -> List(String) {
  case list.first(input) {
    Ok(char) -> {
      let block_size = case int.base_parse(char, 10) {
        Ok(value) -> value
        Error(_) -> 0
      }
      case list.rest(input) {
        Ok(tail) -> {
          expand(
            tail,
            list.append(accumulator, expand_segment(id, block_size, is_file)),
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
    Error(Nil) -> accumulator
  }
}

fn expand_segment(id: Int, times: Int, is_file: Bool) -> List(String) {
  case is_file {
    True -> list.repeat(int.to_string(id), times)
    False -> list.repeat(".", times)
  }
}

// Defragmentation /////////////////////////////////////////////////////////////

pub fn defragment_disk(input: List(String)) -> List(String) {
  io.println("// DEFRAGMENTING..")
  defrag(input)
}

fn defrag(graphemes: List(String)) -> List(String) {
  let first_space_block_pos = find_first_space_block(graphemes, 0)
  let last_file_block_pos = find_last_file_block(graphemes, 0, 0)
  case first_space_block_pos < last_file_block_pos {
    True -> {
      // plog(graphemes, "// DEFRAGGING: ")
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
}

fn find_first_space_block(list: List(String), index: Int) -> Int {
  case list {
    [first, ..rest] ->
      case first == "." {
        True -> index
        False -> find_first_space_block(rest, index + 1)
      }
    [] -> index
  }
}

fn find_last_file_block(list: List(String), index: Int, last_pos: Int) -> Int {
  case list {
    [first, ..rest] -> {
      let updated_last_pos = case first == "." {
        True -> last_pos
        False -> index
      }
      find_last_file_block(rest, index + 1, updated_last_pos)
    }
    [] -> last_pos
  }
}

// Checksum ////////////////////////////////////////////////////////////////////

pub fn determine_checksum(input: List(String)) {
  plog(input, "// OUTPUT:     ")
  let checksum = check(input, 0, 0)
  io.println("// CHECKSUM:   " <> int.to_string(checksum))
}

fn check(list: List(String), sum: Int, index: Int) -> Int {
  let file_id = case list.first(list) {
    Ok(first_digit) ->
      case int.base_parse(first_digit, 10) {
        Ok(num) -> num
        Error(Nil) -> 0
      }
    Error(Nil) -> 0
  }
  let updated_sum = sum + index * file_id
  case list {
    [_, ..rest] -> check(rest, updated_sum, index + 1)
    [] -> sum
  }
}
