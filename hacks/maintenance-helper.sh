#!/bin/bash
set -euo pipefail

# GitHub orgs we're interested in
GITHUB_ORGS="
  enterprise-contract
  konflux-ci
  redhat-appstudio
"

# Additional repos from elsewhere
EXTRA_REPOS="
  tektoncd/chains
"

ORGS_URL="https://api.github.com/orgs"

# In case you need authenticated access to GitHub
#CURL_AUTH="-H \"Authorization: Bearer $TOKEN\""
CURL_AUTH=""

# Produce a sorted, quoted, comma-delimited list of every repo found
# in those orgs, plus the extras
EVERY_REPO=$(
	(
		comma=""
		for org in $GITHUB_ORGS; do
			# The default pagination is 30, hence we need the per_page param here
			repos=$(curl -s $CURL_AUTH $ORGS_URL/${org}/repos?per_page=200 | jq -r '.[]|.full_name')
			for repo in ${repos}; do
				echo "${comma}\"${repo}\""
				comma=","
			done
		done
		for repo in $EXTRA_REPOS; do
			echo "${comma}\"${repo}\""
		done
	) | sort
)

# Generate a config file containing all those repos
EVERY_REPO_CONFIG=$(yq ".git_services[].repos=[$EVERY_REPO]" config.yaml)

# Now use vimdiff to pick and choose from the discovered repos
# Maybe there are some new repos to add, or some obsolete repos to remove
vimdiff "+set ft=yaml" <(echo "$EVERY_REPO_CONFIG") config.yaml
