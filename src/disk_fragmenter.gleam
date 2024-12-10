import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

const title = "// Advent of Code 2024 - Day 9: Disk Fragmenter ////////////////////////////////"

// const example = "2333133121414131402"

// const example = "12345"

const example = "1234649462611144453037831447782650154"

const whole_files = True

pub type Segment {
  File(size: Int, id: Int)
  Free(size: Int)
}

pub fn main() {
  io.println(title)
  let input = case simplifile.read("./src/inputz.txt") {
    Ok(file) -> file
    Error(_error) -> example
  }
  io.println("// READING:    " <> input)
  let highest_id = determine_highest_file_id(input)
  let converted_input = convert_representation(input)
  // io.debug(converted_input)
  converted_input
  |> plog("// CONVERTED:  ")
  |> defragment_disk(highest_id)
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

pub fn defragment_disk(
  input: List(Segment),
  highest_file_id: Int,
) -> List(Segment) {
  case whole_files {
    True -> {
      io.println("// DEFRAGMENTING CAREFULLY..")
      // let last_file_segment_pos = find_last_file_segment(input, 0, 0)
      // let highest_file_id = determine_highest_id(input, last_file_segment_pos)
      // io.println("// HIGHEST ID: " <> int.to_string(highest_file_id))
      defrag_carefully(input, highest_file_id)
    }
    False -> {
      io.println("// DEFRAGMENTING..")
      defrag(input)
    }
  }
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

fn defrag_carefully(segments: List(Segment), file_id: Int) -> List(Segment) {
  case file_id >= 1 {
    True -> {
      plog(segments, "// DEFRAGGING: ")
      let seg_info = case find_file_segment(segments, file_id, 0) {
        Ok(info) -> info
        Error(_) -> #(-1, 0)
      }
      let suitable_space = case
        find_free_segment(segments, seg_info.1, 1, seg_info.0)
      {
        Ok(info) -> info
        Error(_) -> {
          // io.println("// ERROR: No free segment found")
          #(-1, 0)
        }
      }
      case suitable_space.0 > 0 {
        True -> {
          let updated_segments =
            move_file_block(
              segments,
              #(seg_info.0, File(seg_info.1, file_id)),
              #(suitable_space.0, Free(suitable_space.1)),
            )
          defrag_carefully(updated_segments, file_id - 1)
        }
        False -> defrag_carefully(segments, file_id - 1)
      }
    }
    False -> segments
  }
}

fn move_file_block(
  segments: List(Segment),
  file_block: #(Int, Segment),
  free_block: #(Int, Segment),
) -> List(Segment) {
  // io.println("// Attempting to move file block into suitable space")
  let second_half = list.split(segments, file_block.0)
  let list_minus_file =
    list.flatten([
      second_half.0,
      [Free({ file_block.1 }.size)],
      case list.rest(second_half.1) {
        Ok(l) -> l
        Error(_) -> []
      },
    ])
  let first_half = list.split(list_minus_file, free_block.0 - 1)
  let remaining_gap = { free_block.1 }.size - { file_block.1 }.size
  let updated_segments = case remaining_gap > 0 {
    True -> {
      // io.println("// GAP REMAINING")
      list.flatten([
        first_half.0,
        [file_block.1, Free(remaining_gap)],
        case list.rest(first_half.1) {
          Ok(l) -> l
          Error(_) -> []
        },
      ])
    }
    False -> {
      // io.println("// NO GAP")
      list.flatten([
        first_half.0,
        [file_block.1],
        case list.rest(first_half.1) {
          Ok(l) -> l
          Error(_) -> []
        },
      ])
    }
  }
  updated_segments
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

fn find_file_segment(
  list: List(Segment),
  search_id: Int,
  index: Int,
) -> Result(#(Int, Int), Nil) {
  case list {
    [seg, ..rest] -> {
      case seg {
        File(size, id) -> {
          case id == search_id {
            True -> Ok(#(index, size))
            False -> find_file_segment(rest, search_id, index + 1)
          }
        }
        Free(_) -> find_file_segment(rest, search_id, index + 1)
      }
    }
    [] -> Error(Nil)
  }
}

fn find_free_segment(
  list: List(Segment),
  space_required: Int,
  index: Int,
  max_index: Int,
) -> Result(#(Int, Int), Nil) {
  case index < max_index {
    True -> {
      // io.println(
      //   "// Looking for "
      //   <> int.to_string(space_required)
      //   <> " block(s) of free space",
      // )
      case list {
        [seg, ..rest] ->
          case seg {
            Free(size) -> {
              // io.println("// Found a free segment: " <> int.to_string(size))
              case space_required <= size {
                True -> {
                  // io.println("// IT'S A MATCH!")
                  Ok(#(index, size))
                }
                False ->
                  find_free_segment(rest, space_required, index + 1, max_index)
              }
            }
            File(_, _) ->
              find_free_segment(rest, space_required, index + 1, max_index)
          }
        [] -> Error(Nil)
      }
    }
    False -> Error(Nil)
  }
}

// @deprecated("Use the improved function `determine_highest_file_id`")
// fn determine_highest_id(list: List(Segment), position: Int) -> Int {
//   let split_list = list.split(list, at: position)
//   case split_list.1 {
//     [last, ..] | [last] ->
//       case last {
//         File(_, id) -> id
//         Free(_) -> -1
//       }
//     [] -> -1
//   }
// }

fn determine_highest_file_id(input: String) -> Int {
  let length = string.length(input)
  let highest = case int.is_odd(length) {
    True -> { { length - 1 } / 2 } + 1
    False -> length / 2
  }
  io.println("// HIGHEST ID: " <> int.to_string(highest - 1))
  highest - 1
}

// Checksum ////////////////////////////////////////////////////////////////////

pub fn determine_checksum(input: List(Segment)) {
  // plog(input, "// OUTPUT:     ")
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
