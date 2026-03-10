
(*--File Utilities--*)

(*Reads the entire contents of a file into a single string*)
let read_file filename = 
	let file = open_in filename in
	let n = in_channel_length file in
	let s = really_input_string file n in
	close_in file;
	s

(*Count total number of tokens (whitespace seperated). 
	--Used to calculate the total number of variables*)
let count_vars line =
  let words = Str.split (Str.regexp "[ \n\t]+") line in
  List.length words

(*---SAT Output parsing---*)

(* Wxtracts all positively assigned variables from a SAT solver output. 
	ignores things like "SAT"/"UNSAT" and negative variables. *)   
let parse_sat output = 
	let words = Str.split (Str.regexp "[ \n\t]+") output in 
	
	let is_int s = 
		try ignore (int_of_string s); true
		with Failure _ -> false
	in
	let nums = List.filter is_int words in 
	
	List.fold_right (fun s tail -> 
		let n = int_of_string s in 
		if n>0 then n :: tail else tail
	) nums []

(*--Variable Decoding--*)

(* Inverse of varconverter: 
	maps a SAT variable back to (row, column, value). *)
let to_coord var size = 
	let x = var - 1 in
	let v = (x mod size) + 1 in
	let rest = x / size in 
	let c = rest mod size in 
	let r = rest / size in 
	(r, c, v)

(*converts integer to character for printing the grid*)
let int_to_char v size =
	if size<=9 then begin
		if v<10 then char_of_int (v + int_of_char '0')
		else char_of_int (v - 10 + int_of_char 'A')
		end

	else begin 
		let vf = v - 1 in
		if vf<10 then char_of_int (vf + int_of_char '0')
                else char_of_int (vf - 10 + int_of_char 'A')
	end

(*--Grid Reconstruction--*)

(* Finds the value assigned to cell (r,c) by scanning positive (true) SAT variables.
   Returns "." if the cell is unassigned. *)	
let rec find_val r c size true_vars = 
	match true_vars with
	| [] -> "."
	| var :: tail -> 
		let (vr, vc, vv) = to_coord var size in
		if vr = r && vc = c then String.make 1 (int_to_char vv size)
		else find_val r c size tail

(*prints grid row by row*)
let print_grid size true_vars = 
	let rec loop_rows r = 
		if r >=  size then ()
		else begin
			let rec loop_cols c = 
				if c >= size then ()
				else begin 
					Printf.printf "%s" (find_val r c size true_vars);
					loop_cols (c+1)
				end
			in
	loop_cols 0;
			Printf.printf "\n";
			loop_rows (r+1)
		end
	in
	loop_rows 0

(*--MainProgram---*)

(* Reads SAT solver output and prints the solved sudoku grid, 
	if any, else returns "NO SOLUTION" *)
let run_program () =
  
	let content = read_file "sat_output.txt" in
	
	let true_vars = parse_sat content in
	
	let is_unsat = 
		try
			ignore (Str.search_forward (Str.regexp "UNSATISFIABLE") content 0);
			true
		with Not_found -> false
	in
	
	if is_unsat || true_vars = [] then 
		Printf.printf "NO SOLUTION \n"

	else
	begin
		let total_vars = count_vars content in
		let size = int_of_float (exp (log (float_of_int total_vars) /. 3.0)) in
		

		print_grid size true_vars
    	end	


let () = run_program ()
