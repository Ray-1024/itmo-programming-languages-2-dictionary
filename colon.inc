%assign NULL 0
%assign HEADER_SIZE 8

%define CURR_POINTER NULL

%macro colon 2
	%ifid %2
		%2: dq CURR_POINTER
		%define CURR_POINTER %2
	%else
		%fatal "[ERROR] value isn't id [/ERROR]"
	%endif
	%ifstr %1
		db %1, 0
	%else
		%fatal "[ERROR] key isn't string [/ERROR]"
	%endif
%endmacro