const express = require('express');
const { Readability, isProbablyReaderable } = require('@mozilla/readability');
const { JSDOM } = require('jsdom');
const createDOMPurify = require('dompurify');
const TurndownService = require('turndown')

const turndownService = new TurndownService()

const app = express();
app.use(express.json({ limit: '5mb' }));

app.post('/parse', async (req, res) => {
  // GET url
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

  // clean HTML
  const domWindow = new JSDOM('').window;
  const purify = createDOMPurify(domWindow);

  const html = await response.text();
  const cleanHTML = purify.sanitize(html);

  const cleanDOM = new JSDOM(cleanHTML, domOptions);
  const cleanDocument = cleanDOM.window.document;

  if (!isProbablyReaderable(cleanDocument))
    return res.status(204).end();

  // parse via @mozilla/readability
  const reader = new Readability(cleanDocument);
  const article = reader.parse();

  // html -> md
  const markdown = turndownService.turndown(article.content)
  article.content = markdown.replace(/\n+/g, '');

  res.json(article);
});

const port = process.env.PORT || 3001;
app.listen(port, () => console.log(`Ready on port ${port}`));
