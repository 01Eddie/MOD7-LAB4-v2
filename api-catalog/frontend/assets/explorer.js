const suffix=new URLSearchParams(location.search).get('suffix');
if(!/^\d{2}$/.test(suffix??'')) { document.querySelector('#title').textContent='Sufijo inválido'; }
else {
  document.querySelector('#title').textContent=`Documentación API ${suffix}`;
  SwaggerUIBundle({url:`catalog/${suffix}/openapi.json`,dom_id:'#swagger-ui',deepLinking:true,
    presets:[SwaggerUIBundle.presets.apis,SwaggerUIStandalonePreset],layout:'StandaloneLayout'});
}
