# product
- motto: human intelligence; design your own algorithm; curation

# p0
- showing progress
- search is not working (fashion for vishwa)
- user cannot unselect the category ("inbox" -> not "inbox")
- update search to be individual per tenant

# p1

- fallback image / proxy images that dont allow CORS
- search autocomplete for subscriptions

# p2

- notifications

# p-later

- search should include extracted version

- replace subscription skeleton without refresh 
- offline search

- tell the user if extracted content cannot be rendered

- highlighting

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
