"""
Applet: Gitea Issues PRs
Summary: Display Gitea open issues and pull requests
Description: Shows the count of open issues and pull requests for Gitea repositories.
Author: amit
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Gitea logo as base64-encoded PNG (16x16, will be scaled down)
GITEA_LOGO_BASE64 = "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"

# Gitea brand colors
GITEA_GREEN = "#609926"
GITEA_LIGHT = "#87c940"

# Colors
COLOR_ISSUES = "#F59E0B"  # Amber for issues
COLOR_PRS = "#8B5CF6"  # Purple for PRs
COLOR_TEXT = "#FFFFFF"
COLOR_MUTED = "#9CA3AF"
COLOR_ERROR = "#EF4444"
COLOR_ZERO = "#6B7280"  # Gray for zero counts

# Display constants
CACHE_TTL = 300  # 5 minutes
FRAME_DURATION = 5000  # 5 seconds per repo

# Default/preview values
DEFAULT_GITEA_URL = "https://gitea.example.com"
DEFAULT_REPOS = "owner/repo"

def gitea_icon():
    """Gitea logo icon scaled to 8x8 pixels."""
    return render.Image(
        src = base64.decode(GITEA_LOGO_BASE64),
        width = 8,
        height = 8,
    )

def main(config):
    """Main entry point for the applet."""
    gitea_url = config.str("gitea_url", DEFAULT_GITEA_URL)
    api_token = config.str("api_token", "")
    repos_str = config.str("repos", DEFAULT_REPOS)

    # Parse repository list
    repos = [r.strip() for r in repos_str.split(",") if r.strip()]

    if not repos:
        return render_error("No repos configured")

    # Build frames for each repository
    frames = []
    for repo_full in repos:
        parts = repo_full.split("/")
        if len(parts) != 2:
            continue
        owner, repo = parts[0], parts[1]
        frame = render_repo_issues(gitea_url, api_token, owner, repo)
        frames.append(frame)

    if not frames:
        return render_error("Invalid repo format")

    # If only one repo, just show it
    if len(frames) == 1:
        return render.Root(child = frames[0])

    # Multiple repos: cycle through them
    return render.Root(
        delay = FRAME_DURATION,
        child = render.Animation(children = frames),
    )

def render_repo_issues(gitea_url, api_token, owner, repo):
    """Render the issues/PRs display for a single repository."""
    issues_count = get_open_issues_count(gitea_url, api_token, owner, repo)
    prs_count = get_open_prs_count(gitea_url, api_token, owner, repo)

    if issues_count == None and prs_count == None:
        return render_repo_frame(repo, 0, 0, True)

    return render_repo_frame(
        repo,
        issues_count if issues_count != None else 0,
        prs_count if prs_count != None else 0,
        False,
    )

def render_repo_frame(repo_name, issues_count, prs_count, is_error):
    """Render a single frame showing issues and PRs."""
    if is_error:
        return render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Row(
                    cross_align = "center",
                    children = [
                        gitea_icon(),
                        render.Box(width = 2, height = 1),
                        render.Marquee(
                            width = 51,
                            child = render.Text(
                                content = repo_name,
                                font = "tb-8",
                                color = COLOR_TEXT,
                            ),
                        ),
                    ],
                ),
                render.Box(height = 4),
                render.Marquee(
                    width = 64,
                    child = render.Text(
                        content = "API Error",
                        font = "tom-thumb",
                        color = COLOR_ERROR,
                    ),
                ),
            ],
        )

    issues_color = COLOR_ISSUES if issues_count > 0 else COLOR_ZERO
    prs_color = COLOR_PRS if prs_count > 0 else COLOR_ZERO

    return render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            # Header: Gitea icon + repo name
            render.Row(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = [
                    gitea_icon(),
                    render.Box(width = 2, height = 1),
                    render.Marquee(
                        width = 47,
                        child = render.Text(
                            content = repo_name,
                            font = "tb-8",
                            color = COLOR_TEXT,
                        ),
                    ),
                ],
            ),
            # Issues row
            render.Row(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Circle(color = issues_color, diameter = 5),
                    render.Box(width = 3, height = 1),
                    render.Marquee(
                        width = 50,
                        child = render.Text(
                            content = "%d Issues" % issues_count,
                            font = "tom-thumb",
                            color = issues_color,
                        ),
                    ),
                ],
            ),
            # PRs row
            render.Row(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Circle(color = prs_color, diameter = 5),
                    render.Box(width = 3, height = 1),
                    render.Marquee(
                        width = 50,
                        child = render.Text(
                            content = "%d Pull Reqs" % prs_count,
                            font = "tom-thumb",
                            color = prs_color,
                        ),
                    ),
                ],
            ),
        ],
    )

def render_error(message):
    """Render an error state."""
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Row(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        gitea_icon(),
                        render.Box(width = 3, height = 1),
                        render.Text("Gitea Issues", font = "5x8", color = COLOR_TEXT),
                    ],
                ),
                render.Box(height = 4),
                render.Marquee(
                    width = 64,
                    child = render.Text(message, font = "tom-thumb", color = COLOR_ERROR),
                ),
            ],
        ),
    )

def get_open_issues_count(gitea_url, api_token, owner, repo):
    """Get count of open issues from Gitea API."""
    cache_key = "gitea_issues_%s_%s_%s" % (gitea_url, owner, repo)
    cached = cache.get(cache_key)

    if cached:
        return int(cached)

    url = "%s/api/v1/repos/%s/%s/issues" % (gitea_url, owner, repo)
    headers = {}
    if api_token:
        headers["Authorization"] = "token %s" % api_token

    params = {"state": "open", "type": "issues", "limit": "1"}

    resp = http.get(url, headers = headers, params = params, ttl_seconds = CACHE_TTL)

    if resp.status_code != 200:
        print("Gitea API error: %d" % resp.status_code)
        return None

    # Get total count from header if available
    total = resp.headers.get("X-Total-Count", "")
    if total:
        count = int(total)
    else:
        # Fallback: count returned items (less accurate)
        count = len(resp.json())

    cache.set(cache_key, str(count), ttl_seconds = CACHE_TTL)
    return count

def get_open_prs_count(gitea_url, api_token, owner, repo):
    """Get count of open pull requests from Gitea API."""
    cache_key = "gitea_prs_%s_%s_%s" % (gitea_url, owner, repo)
    cached = cache.get(cache_key)

    if cached:
        return int(cached)

    url = "%s/api/v1/repos/%s/%s/pulls" % (gitea_url, owner, repo)
    headers = {}
    if api_token:
        headers["Authorization"] = "token %s" % api_token

    params = {"state": "open", "limit": "1"}

    resp = http.get(url, headers = headers, params = params, ttl_seconds = CACHE_TTL)

    if resp.status_code != 200:
        print("Gitea API error: %d" % resp.status_code)
        return None

    # Get total count from header if available
    total = resp.headers.get("X-Total-Count", "")
    if total:
        count = int(total)
    else:
        # Fallback: count returned items (less accurate)
        count = len(resp.json())

    cache.set(cache_key, str(count), ttl_seconds = CACHE_TTL)
    return count

def get_schema():
    """Define the configuration schema for the app."""
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "gitea_url",
                name = "Gitea URL",
                desc = "Your Gitea instance URL (e.g., https://gitea.example.com)",
                icon = "server",
                default = DEFAULT_GITEA_URL,
            ),
            schema.Text(
                id = "api_token",
                name = "API Token",
                desc = "Gitea personal access token for authentication",
                icon = "key",
                default = "",
            ),
            schema.Text(
                id = "repos",
                name = "Repositories",
                desc = "Comma-separated list of repos (e.g., owner/repo1,owner/repo2)",
                icon = "codeBranch",
                default = DEFAULT_REPOS,
            ),
        ],
    )
