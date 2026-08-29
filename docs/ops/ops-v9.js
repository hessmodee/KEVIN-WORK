(()=>{
  const IDENTITY={
    chat:'#59B6EF',
    ollama:'#79C56A',
    bridge:'#E77AB7',
    reader:'#68D8CE',
    tick:'#F0B74E',
    night:'#B38CFF',
    staging:'#5BD6A2',
    mission:'#FF7F6E',
    benchmark:'#7AA2FF',
    build:'#FF9A3D'
  };
  const STATE={
    idle:'#69716A',
    ready:'#79C56A',
    working:'#79C56A',
    thinking:'#F0B74E',
    cooling:'#F0B74E',
    connecting:'#59B6EF',
    building:'#FF9A3D',
    degraded:'#E46F61',
    offline:'#353B36'
  };

  // Identity belongs to the owl outline only. Every helper is unique.
  try{
    for(const w of WORKERS){if(IDENTITY[w.key])w.c=IDENTITY[w.key];}
  }catch(_){ }

  // One closed outer silhouette only: no head/body/wing geometry is stroked inside it.
  const SILHOUETTE='M22 19 Q31 25 40 25 Q49 18 60 18 Q71 18 80 25 Q89 25 98 19 Q101 35 94 48 Q100 56 97 66 C98 76 98 87 94 96 C90 104 83 108 76 110 C73 114 68 114 60 110 C52 114 47 114 44 110 C37 108 30 104 26 96 C22 87 22 76 23 66 Q20 56 26 48 Q19 35 22 19 Z';
  try{
    owl=function(c){return `<svg class="owl" viewBox="0 0 120 120" aria-hidden="true"><path class="helper-owl-silhouette" d="${SILHOUETTE}" fill="rgba(255,255,255,.006)" stroke="${c}" stroke-width="4.2"/></svg>`};
  }catch(_){ }

  function stateOf(el){
    for(const s of Object.keys(STATE)){if(el.classList.contains(s))return s;}
    return 'idle';
  }
  function applyStateColors(){
    const workers=[...document.querySelectorAll('#topology .worker')];
    const lines=[...document.querySelectorAll('#topology .line')];
    workers.forEach((el,i)=>{
      const st=stateOf(el),sc=STATE[st]||STATE.idle;
      el.style.setProperty('--state',sc);
      if(lines[i])lines[i].style.setProperty('--state',sc);
      const badge=el.querySelector('.state');
      if(badge){badge.dataset.state=st;badge.title=`Live state: ${st}`;}
    });
  }

  const topology=document.getElementById('topology');
  if(topology){
    new MutationObserver(()=>queueMicrotask(applyStateColors)).observe(topology,{childList:true,subtree:true,attributes:true,attributeFilter:['class']});
  }
  applyStateColors();
  setTimeout(applyStateColors,50);
  setTimeout(applyStateColors,500);
})();