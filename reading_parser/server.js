const express = require('express');
const { Readability, isProbablyReaderable } = require('@mozilla/readability');
const { JSDOM } = require('jsdom');

const app = express();
app.use(express.json({ limit: '5mb' }));

app.post('/parse', async (req, res) => {
  try {
    const { html } = req.body;
    if (!html) {
      return res.status(400).json({ error: 'HTML content is required' });
    }

    const dom = new JSDOM(html);
    const document = dom.window.document;

    if (!isProbablyReaderable(document)) {
      return res.status(204).end();
    }

    const reader = new Readability(document);
    const article = reader.parse();
    
    res.json(article);
  } catch (error) {
    console.error('Parsing error:', error);
    res.status(500).json({ error: error.message });
  }
});

const port = process.env.PORT || 3001;
app.listen(port, () => console.log(`Ready on port ${port}`));