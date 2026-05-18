#!/bin/bash
# create_issues.sh — Create all TRI-NET 2026 improvement issues
# Usage: ./create_issues.sh [repo]
#
# After gh auth login, run: ./create_issues.sh gHashTag/tt-trinity-gamma

set -e

REPO="${1:-gHashTag/tt-trinity-gamma}"
ISSUES_DIR="$(dirname "$0")"
GITHUB_CLI="gh"

# Check gh authentication
echo "Checking GitHub CLI..."
if ! $GITHUB_CLI auth status &>/dev/null; then
    echo "ERROR: GitHub CLI not authenticated. Run: gh auth login"
    exit 1
fi

# Issue files in order
ISSUES=(
    "00_EPIC_2026.md"
    "01_CL01_AR_ML_Coprocessor.md"
    "02_CL02_Adversarial_Training.md"
    "03_CL03_Crypto_Audit.md"
    "04_CL04_Coq_Export.md"
    "05_EN01_Subthreshold_Clock.md"
    "06_EN02_Event_Driven_Compute.md"
    "07_EN03_Analog_Neuron.md"
    "08_SN01_Adaptive_LIF.md"
    "09_SN02_Lateral_Inhibition.md"
    "10_SN03_STDP_Learning.md"
    "11_PUB01_Journal_Paper.md"
    "12_PUB02_Conference_Paper.md"
    "13_PUB03_PhD_Dissertation.md"
    "14_OS01_t27_Toolchain_v2.md"
    "15_OS02_CI_CD_Community.md"
    "16_OS03_Python_SDK.md"
)

# Map issue files to issue numbers after creation
declare -A ISSUE_NUMBERS

echo "Creating issues for $REPO..."
echo ""

# Function to parse and create issue
create_issue() {
    local file="$1"
    local filepath="$ISSUES_DIR/$file"

    if [[ ! -f "$filepath" ]]; then
        echo "WARNING: $filepath not found, skipping"
        return
    fi

    echo "Creating issue from $file..."

    # Parse issue metadata
    local title=$(sed -n '/^title:/s/^title: "\(.*\)"$/\1/p' "$filepath")
    local labels=$(sed -n '/^labels:/s/^labels: "\(.*\)"$/\1/p' "$filepath")
    local assignees=$(sed -n '/^assignees:/s/^assignees: "\(.*\)"$/\1/p' "$filepath")
    local body=$(sed -n '/^---$/,/^---$/p' "$filepath" | tail -n +2 | head -n -1)

    # Remove related line from body for now (will add after creation)
    body=$(echo "$body" | sed '/^---$/d')

    # Create issue
    local issue_num=$($GITHUB_CLI issue create \
        --repo "$REPO" \
        --title "$title" \
        --body "$body" \
        --label "$labels" \
        --assignee "$assignees" \
        --json title,number)

    # Extract issue number
    issue_num=$(echo "$issue_num" | grep -o '"number":[0-9]*' | grep -o '[0-9]*')

    ISSUE_NUMBERS["$file"]="$issue_num"
    echo "  → Created #$issue_num"
}

# Create all issues
for issue_file in "${ISSUES[@]}"; do
    create_issue "$issue_file"
    sleep 1  # Rate limiting
done

echo ""
echo "========================================="
echo "Issue Creation Summary"
echo "========================================="
for issue_file in "${ISSUES[@]}"; do
    echo "${issue_file}: #${ISSUE_NUMBERS[$issue_file]}"
done
echo ""
echo "Total issues created: ${#ISSUE_NUMBERS[@]}"
echo ""
echo "Next steps:"
echo "1. Review the epic issue #${ISSUE_NUMBERS["00_EPIC_2026.md"]}"
echo "2. Link all sub-issues to the epic"
echo "3. Add dependencies between issues"