# Compiler

This is a project, written to obtain a credit for a semester, in [Formal Languages and Translation Techniques](https://cs.pwr.edu.pl/gebala/dyd/jftt2020.html), a subject on V semester of Computer Science in [Wrocław University of Science and Technology](https://wppt.pwr.edu.pl/en/).

## Contents
* [Task](#Task)
* [Grammar](#Grammar)
* [Virtual Machine](#Virtual-Machine)
* [Usage](#Usage)
* [Tools](#Tools)

## Task
Using [BISON](https://www.gnu.org/software/bison/) and [FLEX](http://manpages.ubuntu.com/manpages/bionic/man1/freebsd-lex.1.html) create a compiler from simple imperative language into machine code. Specification of both imperative language and virtual machine below.

Compiler should throw multiple types of errors (second declaration of variable, wrong usage of array, etc), as well as error location. In case of no errors, compiler should return code for attached virtual machine. Created code should be optimised to have the smallest possible time complexity (multiplication and division can be made in time logarythmic to value of arguments).

## Grammar
Language can be descibed by the graph below:
<pre><code>
<span style="color: #f00;">program</span>         <span class="km-color-2">-></span> <span class="km-color-3">DECLARE</span> <span class="km-color-1">declarations</span> <span class="km-color-3">BEGIN</span> <span class="km-color-1">commands</span> <span class="km-color-3">END</span>
                <span class="km-color-2">|</span>  <span class="km-color-3">BEGIN</span> <span class="km-color-1">commands</span> <span class="km-color-3">END</span>

declarations    -> declarations , pidentifier
                |  declarations , pidentifier (num :num )
                |  pidentifier
                |  pidentifier (num :num )

commands        -> commands command
                |  command

command         -> identifier := expression ;
                |  IF condition THEN commands ELSE commands ENDIF
                |  IF condition THEN commands ENDIF
                |  WHILE condition DO commands ENDWHILE
                |  REPEAT commands UNTIL condition ;
                |  FOR pidentifier FROM value TO value DO commands ENDFOR
                |  FOR pidentifier FROM value DOWNTO value DO commands ENDFOR
                |  READ identifier ;
                |  WRITE value ;

expression      -> value
                |  value + value
                |  value - value
                |  value * value
                |  value / value
                |  value % value

condition       -> value = value
                |  value != value
                |  value < value
                |  value > value
                |  value <= value
                |  value >= value

value           -> num
                |  identifier

identifier      -> pidentifier
                |  pidentifier ( pidentifier )
                |  pidentifier (num )
</code></pre>

Additionally language should fullfill the rules below:
1. Arithmetic equations use only Natural numbers (e.g. a - b = max{ a - b, 0 }, a / 0 = 0, a % 0 = 0).
2. `+` `-` `*` `/` `%` mean respectively addition, subtraction, multiplication, division and modulo.
3. `=` `!=` `<` `>` `<=` `>=` mean respectively relations equal, not equal, less, more, less or equal, more or equal.
4. `:=` means assignment.
5. `tab(10:100)` means declaration of array of 91 elements, indexed from 10 to 100. Identifier `tab(11)` means 11-th element from array `tab`. Declaration with first number greater then second (starting index greater then ending) should throw an error.
6. `FOR` loop has local iterator, changing +1 or -1 each iteration (depending on used word `TO` or `DOWNTO`).
7. Number of iterations in `FOR` loop is set at the beginning, and cannot be changed inside loop (even if values of beginning / end of loop change).
8. Iterator of `FOR` loop cannot be modified inside loop.
9. `REPEAT-UNTIL` loop ends, when the condition written after `UNTIL` is met (loop should run at least 1 time).
10. Instruction `READ` reads value from stdin and saves into variable. `WRITE` shows value of variable into stdout.
11. The rest of functions are similar to most of programming languages.
12. `pidentifier` can be described with regex `[_a-z]+`.
13. `num` is a Natural number written in decimal `[0-9]+`.
14. Code should be case sensitive.
15. In the program, there can be used comments in format `[ comment ]`. Comments cannot be nested.

The errors found by compiler are as follow:
* `BadArrayScope`
* `UndeclaredVar`
* `UninitializedVar`
* `AlreadyDeclaredVar`
* `BadVarType`
* `UnrecognizedText`

which mostly are pretty self-explanatory.

## Virtual Machine
Virtual machine consists of 6 registers (<code>r<sub>a</sub></code>, <code>r<sub>b</sub></code>, <code>r<sub>c</sub></code>, <code>r<sub>d</sub></code>, <code>r<sub>e</sub></code>, <code>r<sub>f</sub></code>), counter of commands `k`, and array of memmory slots <code>p<sub>i</sub></code> for i < 2<sup>62</sup>.

Machine code follows these rules:
1. Machine works on Natural numbers.
2. Program consists of series of commands, numbered from 0. In each step next command is executed, until `HALT`.
3. At the beginning values of registers and memmory is undefined.
4. In the program, there can be used comments in format `[ comment ]`. Comments cannot be nested.
5. White chars are omitted.
6. Unrecognizable command is thrown as error.

These are possible commands (x,y &#8712; {a, b, c, d, e, f} and j &#8712; &#8484; \ {0}):
| Command | Description | Next Command | Cost |
|:-------:|:-----------:|:------------:|:----:|
| `GET x` | reads value from stdin and saves it in memmory slot <code>p<sub>r<sub>x</sub></sub></code> | k = k + 1 | 100 |
| `PUT x` | shows to stdout a number saved in memmory slot <code>p<sub>r<sub>x</sub></sub></code> | k = k + 1 | 100 |
| `LOAD  x y` | <code>r<sub>x</sub></code> &#8592; <code>p<sub>r<sub>y</sub></sub></code> | k = k + 1 | 20 |
| `STORE x y` | <code>p<sub>r<sub>y</sub></sub></code> &#8592; <code>r<sub>x</sub></code> | k = k + 1 | 50 |
| `ADD x y` | <code>r<sub>x</sub></code> &#8592; <code>r<sub>x</sub></code> + <code>r<sub>y</sub></code> | k = k + 1 | 5 |
| `SUB x y` | <code>r<sub>x</sub></code> &#8592; max{ <code>r<sub>x</sub></code> - <code>r<sub>y</sub></code> , 0 } | k = k + 1 | 5 |
| `RESET x` | <code>r<sub>x</sub></code> &#8592; 0 | k = k + 1 | 1 |
| `INC x` | <code>r<sub>x</sub></code> &#8592; <code>r<sub>x</sub></code> + 1 | k = k + 1 | 1 |
| `DEC x` | <code>r<sub>x</sub></code> &#8592; max{ <code>r<sub>x</sub></code> - 1 , 0 } | k = k + 1 | 1 |
| `SHR x` | <code>r<sub>x</sub></code> &#8592; &#8970; <code>r<sub>x</sub></code> / 2 &#8971; | k = k + 1 | 1 |
| `SHL x` | <code>r<sub>x</sub></code> &#8592; <code>r<sub>x</sub></code> * 2 | k = k + 1 | 1 |
| `JUMP j` | jump to the j-th next command | k = k + j | 1 |
| `JZERO x j` | if <code>r<sub>x</sub> = 0</code>, jump to the j-th next command | k = k + j or k = k + 1 | 1 |
| `JODD x j` | if <code>r<sub>x</sub> </code>is odd, jump to the j-th next command | k = k + j or k = k + 1 | 1 |
| `HALT` | end execution of program | | 0 |


## Usage
Compile program from `infile.imp`:
```
$ make
$ ./kompilator <infile.imp> <outfile.mr> [--debug]
```
*The flag `--debug` is optional. When added, it shows the table of stored and used variables, as well as adds comments to created machine code.*

Then run the program on virtual machine
```
$ make -C virtual_machine/
$ ./virtual_machine/virtual_machine <outfile.mr>
```

## Tools
```
g++     9.3.0
flex    2.6.4
bison   3.5.1
make    4.2.1
```
