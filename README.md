# product
- motto: human intelligence; design your own algorithm; curation

# todo
- treat body as a buffer/file
	- https://honeyryderchuck.gitlab.io/httpx/wiki/Response-Handling#body-httpxresponsebody

- offline search
- support hackernews.com

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