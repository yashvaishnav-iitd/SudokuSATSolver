open List

(* ---Utility helpers--- *)

(* Generates a list of integers from i to j (inclusive). *)
let rec range i j = 
	if i>j
	then []
	else i :: (range (i+1) j)

(* returns all unordered pairs from a list.
   used for generating pairwise SAT constraints. *)
let rec get_pair lst =
	match lst with
	| [] -> []
	| h :: t -> (map (fun x -> (h,x)) t) @ (get_pair t)
	
(* --SAT Variable Encoding-- *)

(* Maps (row, col, value) to a unique SAT variable. *)
let varconverter r c v size = (r * size * size) + (c * size) + (v-1) + 1

(*--Constraint Helpers--*)

(* Pairwise encoding for at-most-one constraint *)
let most_one vars =
	map (fun (v1, v2) -> [-v1; -v2]) (get_pair vars)

(*Exactly one variable in the list (atleast one + atmost one)*)   
let exactly_one_var vars = [vars] @ (most_one vars)

(*Used for generting clauses based on cell, row, column and box constraints*)
let generate_clauses size = 
	let base = int_of_float (sqrt (float_of_int size)) in
	let rows = range 0 (size - 1) in
	let cols = range 0 (size - 1) in
	let vals = range 1 (size) in
	let block_index = range 0 (base -1) in
	

	let get_cell_vars r c = 
		map (fun v -> varconverter r c v size) vals in

	let get_row_vars r v = 
		map (fun c -> varconverter r c v size) cols in 

	let get_col_vars c v = 
		map (fun r -> varconverter r c v size) rows in
	
	let get_box_vars br bc v =
		let r_start = br * base in
		let c_start = bc * base in 
		let box_rows = range r_start (r_start + base -1) in
		let box_cols = range c_start (c_start + base -1) in 

		concat (map (fun r -> 
			map ( fun c -> varconverter r c v size) box_cols
		) box_rows) in

	(*Cell constraint*)
	let cell_con = 
		concat (map ( fun r -> 
			concat (map (fun c ->
				exactly_one_var (get_cell_vars r c)
			) cols)
		) rows) in

	(*Row constraint*)	
	let row_con = 
		concat (map (fun r -> 
			concat (map (fun v ->
				exactly_one_var (get_row_vars r v)
			) vals)
		) rows) in
		
	(*Column constraint*)	
	let col_con = 
		concat (map (fun c ->
			concat (map (fun v -> 
				exactly_one_var (get_col_vars c v)
			) vals)
		) cols) in
		
	(*Box constraint*)	
	let box_con = 
		concat (map (fun br -> 
			concat (map (fun bc ->
				concat (map (fun v ->
					exactly_one_var (get_box_vars br bc v)
				) vals)
			) block_index)
		) block_index) in
		
	cell_con @ row_con @ col_con @ box_con


	
(*--Input Parsing--*)
let read_lines filename = 
	let fle = open_in filename in 
	let rec loop () = 
		try 
			let line = input_line fle in
			line :: (loop ())
		with End_of_file ->
			close_in fle ;
			[]
	in
	
	loop ()

(* Converts the given Sudoku rules into unit clauses.
   Empty cells are ignored. *)	
let parse_fixed lines size = 
	concat (mapi (fun r line -> 
		concat (mapi (fun c char ->
			
			let v = 
				if char>='1' && char<='9' then int_of_char char - int_of_char '0'
				else if char >= 'A' && char <= 'G' then int_of_char char - int_of_char 'A' +10
				else if char = '0' then int_of_char char - int_of_char '0'				
				else -2
			in
			let vf = 
				if size <=9 then v
				else (v + 1)		
			in 
			if vf > 0 then [[varconverter r c vf size]] else []
		) (List.init (String.length line) (fun i -> String.get line i)))
	) lines)

(*--Main Program--*)
let () = 
	let lines = read_lines "input.txt" in 
	
	let size = List.length lines in
	let rule_clauses = generate_clauses size in
	let fixed_clauses = parse_fixed lines size in 
	let all_clauses = rule_clauses @ fixed_clauses in
	
	Printf.printf "p cnf %d %d\n" (size * size * size) (List.length all_clauses);

	let rec print_one_clause lst = 
	begin
	match lst with
	| [] -> ()
	| head :: tail ->
		Printf.printf "%d " head;
		print_one_clause tail
	end
	in
	
	let rec print_all_clauses lst =
	begin
	match lst with 
	| [] -> ()
	| head :: tail ->
		print_one_clause head;
		Printf.printf "0\n";
		print_all_clauses tail
	end
	in
	print_all_clauses all_clauses
