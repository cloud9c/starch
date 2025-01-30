const express = require('express');
const { Readability } = require('@mozilla/readability');
const { JSDOM } = require('jsdom');

const app = express();
app.use(express.json());

app.post('/parse', async (req, res) => {
  try {
    const { html } = req.body;
    if (!html) {
      return res.status(400).json({ error: 'HTML content is required' });
    }

    const dom = new JSDOM(html);
    const reader = new Readability(dom.window.document);
    const article = reader.parse();
    
    res.json(article);
  } catch (error) {
    console.error('Parsing error:', error);
    res.status(500).json({ error: error.message });
  }
});

const port = process.env.PORT || 3001;
app.listen(port, () => console.log(`Ready on port ${port}`));