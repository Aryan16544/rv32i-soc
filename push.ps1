param (
    [string]$CommitMessage = "Automated commit"
)

# Ensure we are in a Git repository
if (-not (Test-Path .git)) {
    Write-Error "Not a git repository."
    exit 1
}

# Check if a remote origin is configured
$remotes = git remote
if (-not $remotes) {
    Write-Host "Warning: No git remotes found. You need to add a remote repository." -ForegroundColor Yellow
    Write-Host "Please run: git remote add origin <your-github-repo-ssh-url>" -ForegroundColor Cyan
    Write-Host "Example: git remote add origin git@github.com:username/repo.git" -ForegroundColor Cyan
    exit 0
}

# Add all files
Write-Host "Adding files..." -ForegroundColor Green
git add -A

# Commit
Write-Host "Committing changes..." -ForegroundColor Green
git commit -m $CommitMessage

# Get current branch
$branch = git branch --show-current
if (-not $branch) {
    $branch = "main"
}

# Push
Write-Host "Pushing to remote origin branch '$branch'..." -ForegroundColor Green
git push -u origin $branch
