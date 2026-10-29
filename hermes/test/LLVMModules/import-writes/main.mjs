import {value} from './value.mjs';
let side=0, caught=0;
try {value=(side++,2);}catch(e){if(e instanceof TypeError)caught++;}
try {value++;}catch(e){if(e instanceof TypeError)caught++;}
try {({value}={value:3});}catch(e){if(e instanceof TypeError)caught++;}
try {for(value of [4]){}}catch(e){if(e instanceof TypeError)caught++;}
if(side!==1||caught!==4||value!==1)throw Error('import assignment timing');
print('import-writes-ok');
