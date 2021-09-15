#!/bin/awk -f 

BEGIN {
    demo_id=0;
    demo_content_id=0;
}

# Demo prompt
$1 ~ /^<[+]/ {
    demo_id++;

    if ( demo_id %2 == 0 ) {
    }
}

$0 ~ /^```/ {
    if ( demo_content_id > 0 ) {
        demo_content_id = 1;
    } else {
        demo_content_id = 0;
    }
}

demo_content_id > 1 {
    demo[NR] = $0;
}

END {
    for (item in demo) {
        print demo[item];
    }
}

