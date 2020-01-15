#!/bin/bash

# $1 branch

curl -XPOST \
 https://api.github.com/graphql \
  -H "Authorization: bearer ${GITHUB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "query": "mutation {
    createPullRequest(input: {
      baseRefName: \"master\",
      headRefName: \"$1\",
      body: \"$1\",
      title: \"$1\",
      repositoryId: \"${REPO_ID}\"
    })
    {
      issue {
        id,
        title,
        url,
        number,
        databaseId
      }
    }
  }"
}
EOF
