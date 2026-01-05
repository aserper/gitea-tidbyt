"""
Applet: Gitea Activity
Summary: Display Gitea repository commit activity
Description: Shows a 14-day activity sparkline and commit counts for Gitea repositories.
Author: amit
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Gitea brand colors
GITEA_GREEN = "#609926"
GITEA_LIGHT = "#87c940"

# Colors
COLOR_BAR = "#22C55E"  # Green for activity bars
COLOR_BAR_LOW = "#166534"  # Darker green for low activity
COLOR_TEXT = "#FFFFFF"
COLOR_MUTED = "#9CA3AF"
COLOR_ERROR = "#EF4444"

# Display constants
BAR_WIDTH = 4
BAR_SPACING = 1
BAR_MAX_HEIGHT = 10
DAYS_TO_SHOW = 14
CACHE_TTL = 900  # 15 minutes
FRAME_DURATION = 5000  # 5 seconds per repo

# Default/preview values
DEFAULT_GITEA_URL = "https://gitea.example.com"
DEFAULT_REPOS = "owner/repo"

def gitea_icon():
    """7x8 pixel git branch icon in Gitea green."""
    G = GITEA_GREEN
    _ = "#00000000"

    return render.Column(
        children = [
            # Row 0: Top commit (3px wide)
            render.Row(children = [
                render.Box(width = 2, height = 1, color = _),
                render.Box(width = 3, height = 1, color = G),
                render.Box(width = 2, height = 1, color = _),
            ]),
            # Row 1: Line down
            render.Row(children = [
                render.Box(width = 3, height = 1, color = _),
                render.Box(width = 1, height = 1, color = G),
                render.Box(width = 3, height = 1, color = _),
            ]),
            # Row 2: Horizontal fork line
            render.Row(children = [
                render.Box(width = 1, height = 1, color = _),
                render.Box(width = 5, height = 1, color = G),
                render.Box(width = 1, height = 1, color = _),
            ]),
            # Row 3: Two branches down
            render.Row(children = [
                render.Box(width = 1, height = 1, color = _),
                render.Box(width = 1, height = 1, color = G),
                render.Box(width = 3, height = 1, color = _),
                render.Box(width = 1, height = 1, color = G),
                render.Box(width = 1, height = 1, color = _),
            ]),
            # Row 4: Continue branches
            render.Row(children = [
                render.Box(width = 1, height = 1, color = _),
                render.Box(width = 1, height = 1, color = G),
                render.Box(width = 3, height = 1, color = _),
                render.Box(width = 1, height = 1, color = G),
                render.Box(width = 1, height = 1, color = _),
            ]),
            # Row 5: Continue branches
            render.Row(children = [
                render.Box(width = 1, height = 1, color = _),
                render.Box(width = 1, height = 1, color = G),
                render.Box(width = 3, height = 1, color = _),
                render.Box(width = 1, height = 1, color = G),
                render.Box(width = 1, height = 1, color = _),
            ]),
            # Row 6: Continue branches
            render.Row(children = [
                render.Box(width = 1, height = 1, color = _),
                render.Box(width = 1, height = 1, color = G),
                render.Box(width = 3, height = 1, color = _),
                render.Box(width = 1, height = 1, color = G),
                render.Box(width = 1, height = 1, color = _),
            ]),
            # Row 7: Bottom commits (2px each)
            render.Row(children = [
                render.Box(width = 2, height = 1, color = G),
                render.Box(width = 3, height = 1, color = _),
                render.Box(width = 2, height = 1, color = G),
            ]),
        ],
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
        frame = render_repo_activity(gitea_url, api_token, owner, repo)
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

def render_repo_activity(gitea_url, api_token, owner, repo):
    """Render the activity display for a single repository."""
    commits = get_commits(gitea_url, api_token, owner, repo)

    if commits == None:
        return render_repo_frame(repo, [], 0, "API Error")

    # Group commits by day
    daily_counts = count_commits_by_day(commits)

    # Calculate total commits
    total = 0
    for c in daily_counts:
        total += c

    return render_repo_frame(repo, daily_counts, total, "%dd" % DAYS_TO_SHOW)

def render_repo_frame(repo_name, daily_counts, total, period_label):
    """Render a single frame showing repo activity."""
    # Build sparkline bars
    bars = build_sparkline(daily_counts)

    return render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            # Header: Gitea icon + repo name + period
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Row(
                        cross_align = "center",
                        children = [
                            gitea_icon(),
                            render.Box(width = 2, height = 1),
                            render.Marquee(
                                width = 39,
                                child = render.Text(
                                    content = repo_name,
                                    font = "tb-8",
                                    color = COLOR_TEXT,
                                ),
                            ),
                        ],
                    ),
                    render.Text(
                        content = period_label,
                        font = "tom-thumb",
                        color = COLOR_MUTED,
                    ),
                ],
            ),
            # Sparkline
            render.Padding(
                pad = (0, 1, 0, 1),
                child = bars,
            ),
            # Total commits
            render.Marquee(
                width = 64,
                child = render.Text(
                    content = "%d commits" % total,
                    font = "tom-thumb",
                    color = COLOR_BAR if total > 0 else COLOR_MUTED,
                ),
            ),
        ],
    )

def build_sparkline(daily_counts):
    """Build a sparkline visualization from daily commit counts."""
    if not daily_counts:
        # Show empty placeholder
        return render.Box(width = 64, height = BAR_MAX_HEIGHT, color = "#1F2937")

    # Find max for scaling (no built-in max in Starlark)
    max_count = 1
    for c in daily_counts:
        if c > max_count:
            max_count = c

    bars = []
    for count in daily_counts:
        # Calculate bar height (minimum 1 pixel if there's activity)
        if count > 0:
            height = int((count * BAR_MAX_HEIGHT) / max_count)
            if height < 1:
                height = 1
            color = COLOR_BAR if count >= max_count / 2 else COLOR_BAR_LOW
        else:
            height = 1
            color = "#374151"  # Very dark gray for zero days

        bars.append(
            render.Padding(
                pad = (0, BAR_MAX_HEIGHT - height, 0, 0),
                child = render.Box(width = BAR_WIDTH, height = height, color = color),
            ),
        )
        bars.append(render.Box(width = BAR_SPACING, height = 1))

    # Remove trailing spacer
    if bars:
        bars = bars[:-1]

    return render.Row(
        main_align = "center",
        cross_align = "end",
        children = bars,
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
                        render.Text("Gitea Activity", font = "5x8", color = COLOR_TEXT),
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

def get_commits(gitea_url, api_token, owner, repo):
    """Fetch recent commits from Gitea API."""
    cache_key = "gitea_commits_%s_%s_%s" % (gitea_url, owner, repo)
    cached = cache.get(cache_key)

    if cached:
        return json.decode(cached)

    url = "%s/api/v1/repos/%s/%s/commits" % (gitea_url, owner, repo)
    headers = {}
    if api_token:
        headers["Authorization"] = "token %s" % api_token

    # Fetch enough commits to cover our time window
    params = {"limit": "100"}

    resp = http.get(url, headers = headers, params = params, ttl_seconds = CACHE_TTL)

    if resp.status_code != 200:
        print("Gitea API error: %d" % resp.status_code)
        return None

    commits = resp.json()

    # Cache the result
    cache.set(cache_key, json.encode(commits), ttl_seconds = CACHE_TTL)

    return commits

def count_commits_by_day(commits):
    """Count commits per day for the last N days."""
    now = time.now()
    counts = [0] * DAYS_TO_SHOW

    for commit in commits:
        # Get commit timestamp
        commit_info = commit.get("commit", {})
        committer = commit_info.get("committer", {})
        date_str = committer.get("date", "")

        if not date_str:
            # Try author date as fallback
            author = commit_info.get("author", {})
            date_str = author.get("date", "")

        if not date_str:
            continue

        # Parse the timestamp
        commit_time = time.parse_time(date_str)
        if not commit_time:
            continue

        # Calculate days ago
        diff = now - commit_time
        days_ago = int(diff.hours / 24)

        if days_ago >= 0 and days_ago < DAYS_TO_SHOW:
            counts[DAYS_TO_SHOW - 1 - days_ago] += 1

    return counts

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
