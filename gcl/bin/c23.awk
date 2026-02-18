#!/usr/bin/awk -f

/^ *ufixnum *maxargs_for_awk *=/ {gsub("="," ");gsub(";"," ");maxargs=$NF+0;next}

/^ *awk_generated_vc_apply_n_lines;$/ {

    if (!maxargs) {printf("error: maxargs unset\n");exit(-1);}
   
    for (n=1;n<=maxargs;n++) {
	for (m=n;m;m--) {
	    printf("\n\tcase %d*%d+%d: return ((object(*)(",n,maxargs+1,m);
            for (i=0;i<m;i++) printf("%sobject",i ? "," : "");
	    printf(",...))f)(");
            for (i=0;i<n;i++) printf("%sx[%d]",i ? "," : "",i);
            printf(");");
	}
    }
    printf("\n");
    
    next;
    
}

/^ *awk_generated_rc_apply_n_lines;$/ {
    
    for (n=0;n<=maxargs;n++) {
	printf("\n\tcase %d: return ((object(*)(",n);
	for (i=0;i<n;i++) printf("%sobject",i ? "," : "");
	printf("))f)(");
	for (i=0;i<n;i++) printf("%sx[%d]",i ? "," : "",i);
	printf(");");
    }
    printf("\n");

    next;
}

{print}
