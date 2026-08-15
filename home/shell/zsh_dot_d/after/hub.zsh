# https://github.com/github/hub/issues/1419
repos_via_hub() {
  local user="${1?}"
  shift 1
  paginate hub api -t graphql -f user="$user" "$@" -f query='
    query($user: String!, $per_page: Int = 100, $after: String) {
      user(login: $user) {
        repositories(first: $per_page, after: $after) {
          nodes {
            nameWithOwner
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
  '
}
paginate() {
  local output cursor
  output="$("$@")"
  cursor="$(awk '/\.hasNextPage/ { has_next=$2 } /\.endCursor/ { if (has_next=="true") print $2 }' <<<"$output")"
  printf "%s\n" "$output"
  [ -z "$cursor" ] || paginate "$@" -f after="$cursor"
}
# USAGE: repos_via_hub "bossjones" | awk '/\.nameWithOwner\t/ { print $2 }'
