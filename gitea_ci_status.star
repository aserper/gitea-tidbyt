"""
Applet: Gitea CI Status
Summary: Display Gitea CI/CD pipeline status
Description: Shows the status of recent workflow runs for Gitea repositories with colored indicators.
Author: amit
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Gitea logo as base64-encoded PNG (16x16, will be scaled down)
GITEA_LOGO_BASE64 = "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"

# Gitea brand colors
GITEA_GREEN = "#609926"
GITEA_LIGHT = "#87c940"

# Colors for different CI states
COLOR_SUCCESS = "#22C55E"  # Green
COLOR_FAILURE = "#EF4444"  # Red
COLOR_RUNNING = "#F59E0B"  # Yellow/Amber
COLOR_PENDING = "#3B82F6"  # Blue
COLOR_CANCELLED = "#6B7280"  # Gray
COLOR_SKIPPED = "#9CA3AF"  # Light gray
COLOR_TEXT = "#FFFFFF"
COLOR_MUTED = "#9CA3AF"

# Display constants
DOT_DIAMETER = 4
DOT_SPACING = 1
MAX_DOTS = 8
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
        frame = render_repo_status(gitea_url, api_token, owner, repo)
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

def render_repo_status(gitea_url, api_token, owner, repo):
    """Render the status display for a single repository."""
    runs = get_action_runs(gitea_url, api_token, owner, repo)

    if runs == None:
        return render_repo_frame(repo, [], "API Error", COLOR_FAILURE)

    if len(runs) == 0:
        return render_repo_frame(repo, [], "No runs", COLOR_CANCELLED)

    # Extract status from runs
    statuses = []
    for run in runs[:MAX_DOTS]:
        status = run.get("status", "unknown")
        conclusion = run.get("conclusion", "")
        statuses.append(get_status_color(status, conclusion))

    # Get latest run info
    latest = runs[0] if runs else None
    if latest:
        status_text = get_status_text(latest.get("status", ""), latest.get("conclusion", ""))
        status_color = get_status_color(latest.get("status", ""), latest.get("conclusion", ""))
        updated = latest.get("updated_at", "")
        time_ago = format_time_ago(updated)
    else:
        status_text = "Unknown"
        status_color = COLOR_CANCELLED
        time_ago = ""

    return render_repo_frame(repo, statuses, status_text + " " + time_ago, status_color)

def render_repo_frame(repo_name, statuses, status_line, primary_color):
    """Render a single frame showing repo status."""
    # Build status dots row
    dots = []
    for color in statuses:
        dots.append(render.Circle(color = color, diameter = DOT_DIAMETER))
        dots.append(render.Box(width = DOT_SPACING, height = 1))

    # Remove trailing spacer
    if dots:
        dots = dots[:-1]

    dots_row = render.Row(
        children = dots,
        main_align = "center",
        cross_align = "center",
    ) if dots else render.Text("No CI data", font = "tom-thumb", color = COLOR_MUTED)

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
                        width = 51,
                        child = render.Text(
                            content = repo_name,
                            font = "tb-8",
                            color = COLOR_TEXT,
                        ),
                    ),
                ],
            ),
            # Status dots
            render.Padding(
                pad = (0, 1, 0, 1),
                child = dots_row,
            ),
            # Status text
            render.Marquee(
                width = 64,
                child = render.Text(
                    content = "CI: " + status_line,
                    font = "tom-thumb",
                    color = primary_color,
                ),
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
                        render.Text("Gitea CI", font = "6x13", color = COLOR_TEXT),
                    ],
                ),
                render.Box(height = 4),
                render.Marquee(
                    width = 64,
                    child = render.Text(message, font = "tom-thumb", color = COLOR_FAILURE),
                ),
            ],
        ),
    )

def get_action_runs(gitea_url, api_token, owner, repo):
    """Fetch recent action runs from Gitea API."""
    cache_key = "gitea_runs_%s_%s_%s" % (gitea_url, owner, repo)
    cached = cache.get(cache_key)

    if cached:
        return json.decode(cached)

    url = "%s/api/v1/repos/%s/%s/actions/runs" % (gitea_url, owner, repo)
    headers = {}
    if api_token:
        headers["Authorization"] = "token %s" % api_token

    resp = http.get(url, headers = headers, ttl_seconds = CACHE_TTL)

    if resp.status_code != 200:
        print("Gitea API error: %d" % resp.status_code)
        return None

    data = resp.json()
    runs = data.get("workflow_runs", [])

    # Cache the result
    cache.set(cache_key, json.encode(runs), ttl_seconds = CACHE_TTL)

    return runs

def get_status_color(status, conclusion):
    """Map Gitea run status/conclusion to a color."""
    if status == "completed":
        if conclusion == "success":
            return COLOR_SUCCESS
        elif conclusion == "failure":
            return COLOR_FAILURE
        elif conclusion == "cancelled":
            return COLOR_CANCELLED
        elif conclusion == "skipped":
            return COLOR_SKIPPED
        else:
            return COLOR_CANCELLED
    elif status == "in_progress" or status == "running":
        return COLOR_RUNNING
    elif status == "queued" or status == "waiting" or status == "pending":
        return COLOR_PENDING
    else:
        return COLOR_CANCELLED

def get_status_text(status, conclusion):
    """Get human-readable status text."""
    if status == "completed":
        if conclusion == "success":
            return "OK"
        elif conclusion == "failure":
            return "FAIL"
        elif conclusion == "cancelled":
            return "CANCELLED"
        else:
            return conclusion.upper() if conclusion else "DONE"
    elif status == "in_progress" or status == "running":
        return "RUNNING"
    elif status == "queued" or status == "waiting":
        return "QUEUED"
    elif status == "pending":
        return "PENDING"
    else:
        return status.upper() if status else "UNKNOWN"

def format_time_ago(timestamp):
    """Format a timestamp as relative time."""
    if not timestamp:
        return ""

    # Parse ISO timestamp
    parsed = time.parse_time(timestamp)
    if not parsed:
        return ""

    return humanize.time(parsed)

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
