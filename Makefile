
.PHONY: default test-qeury show-payload send-data clean

default: send-data

test-qeury:
	curl -s -S -H "Authorization: bearer $(GITHUB_TOKEN)" --data @./query-payload.json https://api.github.com/graphql  

github-data.json:
	curl -s -S -H "Authorization: bearer $(GITHUB_TOKEN)" --data @./query-payload.json \
	https://api.github.com/graphql > github-data.json

repos.json: github-data.json
	jq < github-data.json '[.data.search.edges[] | { repo: .node.repository.nameWithOwner, pr: .node.number } ] | group_by(.repo) |  .[] | { eventType:"GitHubRepoPRs", repo: .[0].repo, count: length } ' > repos.json

totals.json: github-data.json
	jq < github-data.json '{ eventType:"GitHubPRs", count: .data.search.issueCount }' > totals.json

newrelic-payload.json: totals.json repos.json
	jq -s [.[]] totals.json repos.json > newrelic-payload.json

show-payload: newrelic-payload.json
	cat newrelic-payload.json

send-data: newrelic-payload.json
	gzip < newrelic-payload.json | \
	curl -s -S --data-binary @- -H "Content-Type: application/json" \
	-H "X-Insert-Key: $(NEWRELIC_TOKEN)" -H "Content-Encoding: gzip" \
	https://insights-collector.newrelic.com/v1/accounts/62312/events

clean:
	rm -f github-data.json repos.json totals.json newrelic-payload.json

