const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

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

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));