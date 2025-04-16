# product
- motto: human intelligence; design your own algorithm; curation

# p0
- go back arrow

# p1

- fallback image / proxy images that dont allow CORS
- search autocomplete for subscriptions

# p2

- notifications

# plater

- www -> root domain

- replace subscription skeleton without refresh 
- offline search

- tell the user if extracted content cannot be rendered

- highlighting
- progress tracker
- changing document status
- tagging subscriptions

- support mobile/offline app
- uploading custom docs

# competitors
- Readwise Readers
- Google News
- Newsblur

# how to dev
1. `docker compose up`
2. `rails s`
3. (optional) `rails c`

# update ghcr.io key
`export CR_PAT=YOUR_TOKEN`
`echo $CR_PAT | docker login ghcr.io -u cloud9c --password-stdin`
