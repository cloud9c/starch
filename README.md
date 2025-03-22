# product
- motto: human intelligence; design your own algorithm; curation

# FIX NOW NOW NOW

- fallback image / proxy images that dont allow CORS
- search autocomplete

# AFTER FIX NOW

- error message if subscription fails
- timelimit for trying to get website (hackernew.com as example)
- extraction is blocking

## DO LATER

- www -> root domain

- replace subscription skeleton without refresh 
- offline search

- tell the user if extracted content cannot be rendered

- highlighting
- progress tracker
- changing document status
- tagging subscriptions

- support youtube
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