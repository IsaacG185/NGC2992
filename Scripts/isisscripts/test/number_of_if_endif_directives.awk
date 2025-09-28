/^#/ {
	nIf += match($0, "#if") - match($0, "#endif");
}

END {
	if(nIf != 0) {
		print "\nError: Number of #if* and #endif directives are not equal. Check your code again!";
		exit 1;
	}
}
