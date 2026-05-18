#!/bin/bash
# create_all_issues.sh — Create all 16 TRI-NET 2026 improvement issues
# Usage after gh auth login: ./create_all_issues.sh

set -e

GITHUB_CLI="gh"
REPO="gHashTag/tt-trinity-gamma"
ISSUES_DIR=".github/issues"

echo "=========================================="
echo "TRI-NET 2026 — Creating GitHub Issues"
echo "=========================================="
echo ""
echo "Target repository: $REPO"
echo ""

# Check authentication
echo "Checking GitHub CLI authentication..."
if ! $GITHUB_CLI auth status 2>/dev/null | grep -q "Logged in"; then
    echo "❌ ERROR: GitHub CLI not authenticated"
    echo ""
    echo "Please run: gh auth login"
    echo "Then run this script again: ./create_all_issues.sh"
    exit 1
fi
echo "✓ Authenticated as $($GITHUB_CLI auth user)"
echo ""

# Read issue files
ISSUES=(
    "00_EPIC_2026.md|epic,priority:high"
    "01_CL01_AR_ML_Coprocessor.md|CLARA,priority:P0,size:medium"
    "02_CL02_Adversarial_Training.md|CLARA,Gap-1,priority:P0,size:small"
    "03_CL03_Crypto_Audit.md|CLARA,Gap-10,priority:P0,size:small"
    "04_CL04_Coq_Export.md|formal-verification,Coq,priority:P1,size:large"
    "05_EN01_Subthreshold_Clock.md|power-efficiency,priority:P0,size:medium"
    "06_EN02_Event_Driven_Compute.md|power-efficiency,neuromorphic,priority:P0,size:medium"
    "07_EN03_Analog_Neuron.md|power-efficiency,analog,research,priority:P1,size:large"
    "08_SN01_Adaptive_LIF.md|neuromorphic,SNN,priority:P1,size:medium"
    "09_SN02_Lateral_Inhibition.md|neuromorphic,cortex,priority:P1,size:medium"
    "10_SN03_STDP_Learning.md|neuromorphic,learning,STDP,priority:P1,size:medium"
    "11_PUB01_Journal_Paper.md|publication,paper,priority:P2,size:large"
    "12_PUB02_Conference_Paper.md|publication,paper,priority:P2,size:medium"
    "13_PUB03_PhD_Dissertation.md|publication,PhD,priority:P2,size:large"
    "14_OS01_t27_Toolchain_v2.md|toolchain,t27,priority:P2,size:large"
    "15_OS02_CI_CD_Community.md|devops,CI-CD,priority:P2,size:small"
    "16_OS03_Python_SDK.md|tooling,Python,SDK,priority:P2,size:medium"
)

# Store issue numbers
declare -A ISSUE_NUMBERS

echo "Creating 17 issues..."
echo ""

for issue_info in "${ISSUES[@]}"; do
    IFS='|' read -r file labels <<< "$issue_info"
    filepath="$ISSUES_DIR/$file"

    if [[ ! -f "$filepath" ]]; then
        echo "⚠️  WARNING: $filepath not found, skipping"
        continue
    fi

    # Parse title
    title=$(grep -m1 '^title:' "$filepath" | sed 's/^title: *//' | tr -d '"')

    # Extract body (between --- markers)
    body=$(sed -n '/^---$/,/^---$/p' "$filepath" | tail -n +2 | head -n -1)

    # Remove Related line (will add after creation)
    body=$(echo "$body" | sed '/^---$/d')

    # Create issue
    echo "📝 Creating: $title"
    result=$($GITHUB_CLI issue create \
        --repo "$REPO" \
        --title "$title" \
        --body "$body" \
        --label "$labels" \
        --assignee gHashTag)

    # Extract issue number
    issue_num=$(echo "$result" | grep -o '"number":[0-9]*' | grep -o '[0-9]*')

    if [[ -n "$issue_num" ]]; then
        ISSUE_NUMBERS["$file"]="$issue_num"
        echo "   ✓ Created issue #$issue_num"
    else
        echo "   ✗ Failed to create issue"
    fi

    sleep 0.5  # Rate limiting
    echo ""
done

echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "Total issues created: ${#ISSUE_NUMBERS[@]}"
echo ""
echo "Issue numbers:"
for file in "${!ISSUE_NUMBERS[@]}"; do
    if [[ -n "${ISSUE_NUMBERS[$file]}" ]]; then
        echo "  $file → #${ISSUE_NUMBERS[$file]}"
    else
        echo "  $file → FAILED"
    fi
done
echo ""
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Review the EPIC issue:"
if [[ -n "${ISSUE_NUMBERS["00_EPIC_2026.md"]}" ]]; then
    echo "   https://github.com/$REPO/issues/${ISSUE_NUMBERS["00_EPIC_2026.md"]}"
else
    echo "   (EPIC not created)"
fi
echo ""
echo "2. Link all sub-issues to the EPIC"
echo "   - Open each issue"
echo "   - Add: 'Related to #[EPIC_NUMBER]' in comments"
echo "   - OR edit EPIC to list: 'Closes #[N1], #[N2], ...'"
echo ""
echo "3. Add dependencies between issues:"
echo "   - Use 'Blocks:' label"
echo "   - Reference other issues in description"
echo ""
echo "✓ Done! Issues are now tracked in GitHub."