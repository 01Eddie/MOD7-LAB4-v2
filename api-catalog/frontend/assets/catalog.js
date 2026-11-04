const tbody = document.querySelector('#table');
const summary = document.querySelector('#summary');
async function main() {
  try {
    const suffixes = await (await fetch('manifest.json',{cache:'no-store'})).json();
    const all = await Promise.all(suffixes.map(async suffix => {
      try { const r=await fetch(`catalog/${suffix}/metadata.json?ts=${Date.now()}`); if(r.ok) return await r.json(); } catch {}
      return {suffix,apiName:`cuentas-api-${suffix}`,statusCode:'PENDIENTE',stages:{}};
    }));
    tbody.replaceChildren();
    for (const a of all) {
      const tr=document.createElement('tr');
      const cells=[a.suffix,a.apiName,a.statusCode,a.stages?.test?'Disponible':'—',a.stages?.prod?'Disponible':'—'];
      for(const v of cells){const td=document.createElement('td');td.textContent=v;tr.appendChild(td);}
      const td=document.createElement('td');
      if(a.statusCode!=='PENDIENTE') {const link=document.createElement('a');link.href=`explorer.html?suffix=${encodeURIComponent(a.suffix)}`;link.textContent='Ver OpenAPI';td.appendChild(link);}
      else td.textContent='Pendiente';
      tr.appendChild(td);tbody.appendChild(tr);
    }
    summary.textContent=`${all.filter(a=>a.statusCode!=='PENDIENTE').length} / ${all.length} APIs publicadas`;
  } catch(e) {summary.textContent=`No se pudo cargar el catálogo: ${e.message}`;}
}
main();
