const request = require('supertest');
const express = require('express');

const app = express();

app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Cloud Platform Starter',
    version: '1.1.0'
  });
});

app.get('/health', (req, res) => {
  res.json({ healthy: true });
});

describe('Application endpoints', () => {
  test('GET / returns status ok', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  test('GET /health returns healthy true', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.healthy).toBe(true);
  });
});