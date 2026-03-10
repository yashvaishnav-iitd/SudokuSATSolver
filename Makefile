all:
	ocamlc -I +str -o sudoku2cnf str.cma sudoku2cnf.ml
	ocamlc -I +str -o sol2grid str.cma sol2grid.ml


run: all
	./sudoku2cnf input.txt > problem.cnf
	z3 -dimacs problem.cnf > sat_output.txt
	./sol2grid sat_output.txt > output.txt


clean:
	rm -f sudoku2cnf sol2grid *.cmi *.cmo problem.cnf sat_output.txt output.txt
