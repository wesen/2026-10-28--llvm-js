let x; const get=()=>x; print(get()===undefined); x=7; print(get());
function f(){const read=()=>value;try{read();}catch(e){print(e.name);}let value=undefined;print(read()===undefined);value=9;print(read());}f();
