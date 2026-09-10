(()=>{
'use strict';
// GREEN HQ truth overlay. BLOCKED_INVOCATION_RUNTIME is fail-closed work, not a sick platform.
function contStatus(){return String(window.__kevinContinuation?.status||'').toUpperCase()}
const wrap=fn=>{
 if(typeof window[fn]!=='function')return;
 const orig=window[fn];
 window[fn]=function(d,s){
  if(contStatus()==='BLOCKED_INVOCATION_RUNTIME')return fn==='kevinState'?'blocked':['blocked'];
  return orig(d,s);
 };
};
wrap('kevinStates');
wrap('kevinState');
})();
