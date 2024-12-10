import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

const title = "// Advent of Code 2024 - Day 9: Disk Fragmenter ////////////////////////////////"

const example = "2333133121414131402"

// const example = "12345"

const whole_files = False

pub type Segment {
  File(size: Int, id: Int)
  Free(size: Int)
}

pub fn main() {
  io.println(title)
  let input = case simplifile.read("./src/inputz.txt") {
    Ok(file) -> file
    Error(error) -> {
      io.debug(error)
      example
    }
  }
  io.println("// READING:    " <> input)
  let converted_input = convert_representation(input)
  io.debug(converted_input)
  converted_input
  |> plog("// CONVERTED:  ")
  |> defragment_disk()
  |> plog("// DEFRAGGED:  ")
  |> determine_checksum()
}

/// Logs a List(String) with a given String prefix /////////////////////////////
pub fn plog(input: List(Segment), prefix: String) -> List(Segment) {
  let seg_string =
    list.map(input, fn(seg) {
      case seg {
        File(size, id) -> string.repeat(int.to_string(id), size)
        Free(size) -> string.repeat(".", size)
      }
    })
  io.println(prefix <> string.join(seg_string, ""))
  input
}

//　Conversion //////////////////////////////////////////////////////////////////

pub fn convert_representation(input: String) -> List(Segment) {
  expand(string.to_graphemes(input), [], 0, True)
}

fn expand(
  input: List(String),
  accumulator: List(Segment),
  id: Int,
  is_file: Bool,
) -> List(Segment) {
  case list.first(input) {
    Ok(char) -> {
      let block_size = case int.base_parse(char, 10) {
        Ok(value) -> value
        Error(_) -> 0
      }
      case list.rest(input) {
        Ok(tail) -> {
          let seg = case is_file {
            True -> File(block_size, id)
            False -> Free(block_size)
          }
          expand(
            tail,
            list.append(accumulator, expand_segment(seg)),
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

fn expand_segment(seg: Segment) -> List(Segment) {
  case whole_files {
    True -> {
      case seg {
        File(_, _) -> [seg]
        Free(_) -> [seg]
      }
    }
    False -> {
      case seg {
        File(size, id) -> list.repeat(File(1, id), size)
        Free(size) -> list.repeat(Free(1), size)
      }
    }
  }
}

// Defragmentation /////////////////////////////////////////////////////////////

pub fn defragment_disk(input: List(Segment)) -> List(Segment) {
  io.println("// DEFRAGMENTING..")
  defrag(input)
}

fn defrag(segments: List(Segment)) -> List(Segment) {
  let first_space_block_pos = find_first_free_segment(segments, 0)
  let last_file_block_pos = find_last_file_segment(segments, 0, 0)
  case first_space_block_pos < last_file_block_pos {
    True -> {
      plog(segments, "// DEFRAGGING: ")
      let second_half = list.split(segments, last_file_block_pos)
      let file_block_id = case list.first(second_half.1) {
        Ok(file) ->
          case file {
            File(_, id) -> id
            _ -> -1
          }
        Error(_) -> -1
      }
      let tmp_list =
        list.flatten([
          second_half.0,
          [Free(1)],
          case list.rest(second_half.1) {
            Ok(l) -> l
            Error(_) -> []
          },
        ])
      let first_half = list.split(tmp_list, first_space_block_pos)
      let updated_segments =
        list.flatten([
          first_half.0,
          [File(1, file_block_id)],
          case list.rest(first_half.1) {
            Ok(l) -> l
            Error(_) -> []
          },
        ])
      defrag(updated_segments)
    }
    False -> segments
  }
}

fn find_first_free_segment(list: List(Segment), index: Int) -> Int {
  case list {
    [first, ..rest] ->
      case first {
        Free(_) -> index
        File(_, _) -> find_first_free_segment(rest, index + 1)
      }
    [] -> index
  }
}

fn find_last_file_segment(list: List(Segment), index: Int, last_pos: Int) -> Int {
  case list {
    [first, ..rest] -> {
      let updated_last_pos = case first {
        Free(_) -> last_pos
        File(_, _) -> index
      }
      find_last_file_segment(rest, index + 1, updated_last_pos)
    }
    [] -> last_pos
  }
}

// Checksum ////////////////////////////////////////////////////////////////////

pub fn determine_checksum(input: List(Segment)) {
  plog(input, "// OUTPUT:     ")
  let checksum = check(map_occupied_space(input, []), 0, 0)
  io.println("// CHECKSUM:   " <> int.to_string(checksum))
}

fn map_occupied_space(input: List(Segment), accumulator: List(Int)) -> List(Int) {
  case input {
    [first, ..rest] ->
      case first {
        File(size, id) -> {
          map_occupied_space(
            rest,
            list.append(accumulator, list.repeat(id, size)),
          )
        }
        Free(size) -> {
          map_occupied_space(
            rest,
            list.append(accumulator, list.repeat(0, size)),
          )
        }
      }
    [] -> accumulator
  }
}

fn check(list: List(Int), sum: Int, index: Int) -> Int {
  let file_id = case list.first(list) {
    Ok(first) -> first
    Error(Nil) -> 0
  }
  let updated_sum = sum + index * file_id
  case list {
    [_, ..rest] -> check(rest, updated_sum, index + 1)
    [] -> sum
  }
}
