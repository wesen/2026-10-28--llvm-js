print(this===globalThis);
function sloppy(){return this===globalThis;}print(sloppy());
function strict(){'use strict';return this===undefined;}print(strict());
let o={x:9,f(){return ()=>this.x;}};let g=o.f();print(g());
print(typeof Math,typeof doesNotExist);
let frozen=Object.freeze({x:1});
function strictWrite(){'use strict';frozen.x=2;}
try{strictWrite();}catch(e){print(e.name);}print(frozen.x);
