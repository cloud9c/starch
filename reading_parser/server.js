const express = require('express');
const { Readability, isProbablyReaderable } = require('@mozilla/readability');
const { JSDOM } = require('jsdom');
const createDOMPurify = require('dompurify');

const app = express();
app.use(express.json({ limit: '5mb' }));

app.post('/parse', async (req, res) => {
  const { url } = req.body;
  if (!url)
    return res.status(400).json({ error: 'URL is required' });

  const parsedUrl = new URL(url);
  const domOptions = {
    url: `${parsedUrl.protocol}//${parsedUrl.host}`
  };

  const response = await fetch(url);
  if (!response.ok) {
    return res.status(response.status).json({ 
      error: `Failed to fetch URL: ${response.statusText}` 
    });
  }

  let html = await response.text();
  html = html.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '');
  html = html.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '');

  const domWindow = new JSDOM('').window;
  const purify = createDOMPurify(domWindow);

  const cleanHTML = purify.sanitize(html);

  const cleanDOM = new JSDOM(cleanHTML, domOptions);
  const cleanDocument = cleanDOM.window.document;

  if (!isProbablyReaderable(cleanDocument))
    return res.status(204).end();

  const reader = new Readability(cleanDocument);
  const article = reader.parse();

  res.json(article);
});

const port = process.env.PORT || 3001;
app.listen(port, () => console.log(`Ready on port ${port}`));