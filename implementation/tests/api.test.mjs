import test from 'node:test';
import assert from 'node:assert/strict';
import {handler, ENABLE_POST} from '../src/index.mjs';
const request = (httpMethod, id, body) => handler({httpMethod,pathParameters:{'cliente-id':id},body:body && JSON.stringify(body)});
test('GET cliente conocido responde 200 con datos Lambda', async () => {
  const r = await request('GET','CLI001');
  assert.equal(r.statusCode,200);
  assert.equal(JSON.parse(r.body).origen,'LAMBDA');
});
test('GET inexistente responde 404', async () => assert.equal((await request('GET','CLI999')).statusCode,404));
test('identificador inválido responde 400', async () => assert.equal((await request('GET','abc')).statusCode,400));
test('POST habilitado valida campos y devuelve 201', {skip:!ENABLE_POST}, async () => {
  assert.equal((await request('POST','CLI001',{tipo:'AHORROS',moneda:'PEN',titular:'Persona'})).statusCode,201);
  assert.equal((await request('POST','CLI001',{tipo:'INVALIDO',moneda:'PEN',titular:'Persona'})).statusCode,400);
});
