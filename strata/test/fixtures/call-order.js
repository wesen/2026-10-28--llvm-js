let log='';
let o={get f(){log+='get;';return function(x){log+='call;';return x;};}};
function arg(){log+='arg;';return 3;}
print(o.f(arg()),log);
