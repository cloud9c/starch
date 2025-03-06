# product
- motto: human intelligence; design your own algorithm; curation

# todo
- treat body as a buffer/file
	- https://honeyryderchuck.gitlab.io/httpx/wiki/Response-Handling#body-httpxresponsebody

- change between original vs extracted
- make sure search only searches for 1
- original vs extracted global and feed settings

- if reading parser fails, need to try again

- highlighting
- progress tracker
- changing document status
- tagging subscriptions

- support youtube
- support mobile download
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