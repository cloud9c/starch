const express = require('express');
const { Readability, isProbablyReaderable } = require('@mozilla/readability');
const { JSDOM } = require('jsdom');
const createDOMPurify = require('dompurify');

const app = express();
app.use(express.json({ limit: '5mb' }));

app.post('/parse', async (req, res) => {
  try {
    const { html, url } = req.body;
    if (!html || !url) {
      return res.status(400).json({ error: 'HTML content is required' });
    }

    const domOptions = {
      url: url
    };

    const dom = new JSDOM(html, domOptions);
    const DOMPurify = createDOMPurify(dom.window);

    const cleanHTML = DOMPurify.sanitize(html);
    const cleanDOM = new JSDOM(cleanHTML, domOptions);
    const cleanDocument = cleanDOM.window.document;

    if (!isProbablyReaderable(cleanDocument)) {
      return res.status(204).end();
    }

    const reader = new Readability(cleanDocument);
    const article = reader.parse();
    
    res.json(article);
  } catch (error) {
    console.error('Parsing error:', error);
    res.status(500).json({ error: error.message });
  }
});

const port = process.env.PORT || 3001;
app.listen(port, () => console.log(`Ready on port ${port}`));