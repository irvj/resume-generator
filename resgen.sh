#!/bin/bash

# Resgen: Script to generate resume PDFs with optional anonymization
# Version: 1.0.0
# Usage: ./resgen.sh [OPTIONS] <markdown_file>

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script version
VERSION="1.0.0"

# Default values
ANONYMIZE=false
CSS_FILE="resume.css"
INPUT_MD=""
QUIET=false
DRY_RUN=false
KEEP_TEMP=false
FORCE=false
ANON_NAME="anon_resume.pdf"
OUTPUT_DIR="."
REPLACEMENTS_FILE="replacements.txt"

# Colors for output (if not quiet)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cleanup function
cleanup() {
    if [ "$KEEP_TEMP" = false ]; then
        rm -f anon_resume.md 2>/dev/null || true
    fi
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

# Logging functions
log_info() {
    if [ "$QUIET" = false ]; then
        echo -e "${NC}$1${NC}" >&2
    fi
}

log_success() {
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓ $1${NC}" >&2
    fi
}

log_warning() {
    if [ "$QUIET" = false ]; then
        echo -e "${YELLOW}⚠ $1${NC}" >&2
    fi
}

log_error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

# Help function
show_help() {
    cat << EOF
Resgen: Resume PDF Generator v${VERSION}

DESCRIPTION:
    Generates a PDF version of your resume from markdown. By default, only creates
    the original resume. Use the --anon flag to also generate an anonymized
    version with personal information replaced for public sharing.

USAGE:
    $0 [OPTIONS] <markdown_file>

ARGUMENTS:
    <markdown_file>        Path to your resume markdown file

OPTIONS:
    --anon, -a             Also generate anonymized version
    --css <file>           Use custom CSS file (defaults to resume.css)
    --anon-name <name>     Custom name for anonymized PDF (default: anon_resume.pdf)
    --output-dir <dir>     Output directory for generated files (default: current)
    --replacements <file>  Custom replacements file (default: replacements.txt)
    --quiet, -q            Minimal output
    --dry-run              Preview operations without executing
    --keep-temp            Keep temporary files for debugging
    --force, -f            Automatically overwrite existing files without prompting
    --version, -v          Show version information
    --help, -h             Show this help message and exit

EXAMPLES:
    $0 my_resume.md                                    # Generate only original PDF
    $0 --anon my_resume.md                             # Generate both PDFs
    $0 -a my_resume.md                                 # Same as above (short flag)
    $0 --css custom.css --anon my_resume.md            # Custom CSS + anonymization
    $0 --anon-name private.pdf --anon my_resume.md     # Custom anon filename
    $0 --output-dir ./output --anon my_resume.md       # Custom output directory
    $0 --dry-run --anon my_resume.md                   # Preview what would happen
    $0 --force --anon my_resume.md                     # Auto-overwrite existing files
    $0 -faq my_resume.md                               # Force + anon + quiet (stacked flags)

OUTPUT FILES:
    • <basename>.pdf       Original resume (same name as input file)
    • <anon-name>          Anonymized version (only with --anon flag)

REQUIREMENTS:
    • pandoc              For markdown to HTML conversion
    • weasyprint          For HTML to PDF conversion
    • CSS stylesheet      resume.css by default, or specify with --css
    • replacements.txt    File containing replacement rules (only needed with --anon)

ANONYMIZATION:
    When using --anon, the script uses replacements.txt to replace personal information.
    Each line should be in format: original_text|replacement_text

EOF
}

# Cross-platform sed function
safe_sed() {
    local pattern="$1"
    local file="$2"

    # Detect OS and use appropriate sed syntax
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS/BSD sed
        if command -v gsed &> /dev/null; then
            gsed -i "$pattern" "$file"
        else
            sed -i '' "$pattern" "$file"
        fi
    else
        # GNU sed (Linux)
        sed -i "$pattern" "$file"
    fi
}

# Validate file paths and permissions
validate_paths() {
    # Check if we can write to output directory
    if [ ! -w "$OUTPUT_DIR" ]; then
        log_error "Cannot write to output directory: $OUTPUT_DIR"
        exit 1
    fi

    # Check if output files already exist
    local output_pdf="${OUTPUT_DIR}/$(basename "$INPUT_MD" .md).pdf"
    if [ -f "$output_pdf" ] && [ "$DRY_RUN" = false ]; then
        if [ "$FORCE" = true ]; then
            if [ "$QUIET" = false ]; then
                echo -e "${YELLOW}⚠ Output file $output_pdf already exists - overwriting due to --force${NC}" >&2
            fi
        else
            echo -e "${YELLOW}⚠ Output file $output_pdf already exists${NC}" >&2
            read -p "Overwrite? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Operation cancelled" >&2
                exit 0
            fi
        fi
    fi

    if [ "$ANONYMIZE" = true ]; then
        local anon_output="${OUTPUT_DIR}/$ANON_NAME"
        if [ -f "$anon_output" ] && [ "$DRY_RUN" = false ]; then
            if [ "$FORCE" = true ]; then
                if [ "$QUIET" = false ]; then
                    echo -e "${YELLOW}⚠ Anonymized output file $anon_output already exists - overwriting due to --force${NC}" >&2
                fi
            else
                echo -e "${YELLOW}⚠ Anonymized output file $anon_output already exists${NC}" >&2
                read -p "Overwrite? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo "Operation cancelled" >&2
                    exit 0
                fi
            fi
        fi
    fi
}

# Validate replacements file format
validate_replacements() {
    if [ ! -f "$REPLACEMENTS_FILE" ]; then
        return 0
    fi

    local line_num=0
    local errors=0

    while IFS= read -r line || [ -n "$line" ]; do
        ((line_num++))

        # Skip comments and empty lines
        if [[ "$line" =~ ^#.*$ ]] || [ -z "$line" ]; then
            continue
        fi

        # Check if line contains exactly one pipe character
        if [[ $(echo "$line" | tr -cd '|' | wc -c) -ne 1 ]]; then
            log_warning "Line $line_num in $REPLACEMENTS_FILE: malformed format (should be 'original|replacement')"
            ((errors++))
        fi
    done < "$REPLACEMENTS_FILE"

    if [ $errors -gt 0 ]; then
        log_warning "Found $errors formatting issues in $REPLACEMENTS_FILE"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled"
            exit 0
        fi
    fi
}

# Sanitize replacement patterns for sed safety
sanitize_for_sed() {
    local text="$1"
    # Escape special sed characters
    printf '%s\n' "$text" | sed 's/[[\.*^$()+?{|]/\\&/g'
}

# Execute command with timeout
execute_with_timeout() {
    local timeout_duration="$1"
    local description="$2"
    shift 2

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would execute: $*"
        return 0
    fi

    log_info "$description"

    if command -v timeout &> /dev/null; then
        timeout "$timeout_duration" "$@"
    else
        # Fallback for systems without timeout command
        "$@"
    fi
}

# Get file size in human readable format
get_file_size() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f%z "$1" 2>/dev/null || echo "0"
    else
        stat -c%s "$1" 2>/dev/null || echo "0"
    fi
}

format_file_size() {
    local size="$1"
    if [ "$size" -ge 1048576 ]; then
        echo "$(( size / 1048576 ))MB"
    elif [ "$size" -ge 1024 ]; then
        echo "$(( size / 1024 ))KB"
    else
        echo "${size}B"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --version|-v)
            echo "Resgen: Resume PDF Generator v${VERSION}"
            exit 0
            ;;
        --anon|-a)
            ANONYMIZE=true
            shift
            ;;
        --css)
            if [ -n "$2" ] && [[ "$2" != -* ]]; then
                CSS_FILE="$2"
                shift 2
            else
                log_error "--css requires a filename"
                exit 1
            fi
            ;;
        --anon-name)
            if [ -n "$2" ] && [[ "$2" != -* ]]; then
                ANON_NAME="$2"
                shift 2
            else
                log_error "--anon-name requires a filename"
                exit 1
            fi
            ;;
        --output-dir)
            if [ -n "$2" ] && [[ "$2" != -* ]]; then
                OUTPUT_DIR="$2"
                shift 2
            else
                log_error "--output-dir requires a directory path"
                exit 1
            fi
            ;;
        --replacements)
            if [ -n "$2" ] && [[ "$2" != -* ]]; then
                REPLACEMENTS_FILE="$2"
                shift 2
            else
                log_error "--replacements requires a filename"
                exit 1
            fi
            ;;
        --quiet|-q)
            QUIET=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --keep-temp)
            KEEP_TEMP=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        -*)
            # Handle stacked short flags (e.g., -faq)
            if [[ "$1" =~ ^-[a-zA-Z]+$ ]]; then
                flags="${1#-}"  # Remove the leading dash
                i=0
                while [ $i -lt ${#flags} ]; do
                    flag="${flags:$i:1}"
                    case $flag in
                        a)
                            ANONYMIZE=true
                            ;;
                        f)
                            FORCE=true
                            ;;
                        q)
                            QUIET=true
                            ;;
                        h)
                            show_help
                            exit 0
                            ;;
                        v)
                            echo "Resgen: Resume PDF Generator v${VERSION}"
                            exit 0
                            ;;
                        *)
                            log_error "Unknown flag: -$flag"
                            echo "Use --help or -h for more information"
                            exit 1
                            ;;
                    esac
                    ((i++))
                done
                shift
            else
                log_error "Unknown option: $1"
                echo "Use --help or -h for more information"
                exit 1
            fi
            ;;
        *)
            if [ -z "$INPUT_MD" ]; then
                INPUT_MD="$1"
            else
                log_error "Multiple input files specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if an argument was provided
if [ -z "$INPUT_MD" ]; then
    log_error "No input file specified"
    echo "Usage: $0 [OPTIONS] <markdown_file>"
    echo "Use --help or -h for more information"
    exit 1
fi

# Check if the input file exists and is readable
if [ ! -f "$INPUT_MD" ]; then
    log_error "File '$INPUT_MD' not found!"
    exit 1
fi

if [ ! -r "$INPUT_MD" ]; then
    log_error "Cannot read file '$INPUT_MD'"
    exit 1
fi

# Check if markdown file is empty
if [ ! -s "$INPUT_MD" ]; then
    log_error "Input file '$INPUT_MD' is empty"
    exit 1
fi

# Create output directory if it doesn't exist
if [ ! -d "$OUTPUT_DIR" ]; then
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$OUTPUT_DIR" || {
            log_error "Cannot create output directory: $OUTPUT_DIR"
            exit 1
        }
    fi
fi

# Extract the base name without extension for the output PDF
BASE_NAME=$(basename "$INPUT_MD" .md)
OUTPUT_PDF="${OUTPUT_DIR}/${BASE_NAME}.pdf"

# Validate paths and permissions
validate_paths

# Check for required dependencies
log_info "Checking dependencies..."

if ! command -v pandoc &> /dev/null; then
    log_error "pandoc is not installed."
    echo "Install with: brew install pandoc (macOS) or apt-get install pandoc (Ubuntu)"
    exit 1
fi

if ! command -v weasyprint &> /dev/null; then
    log_error "weasyprint is not installed."
    echo "Install with: pip install weasyprint"
    exit 1
fi

# Check if CSS file exists
if [ ! -f "$CSS_FILE" ]; then
    log_error "CSS file '$CSS_FILE' not found!"
    echo "This CSS file is required for PDF styling."
    exit 1
fi

# Basic CSS validation
if [ ! -s "$CSS_FILE" ]; then
    log_warning "CSS file '$CSS_FILE' is empty"
fi

log_success "All dependencies found"

if [ "$QUIET" = false ]; then
    echo ""
    log_info "Starting resume PDF generation..."
    log_info "Input file: $INPUT_MD"
    log_info "CSS file: $CSS_FILE"
    log_info "Output directory: $OUTPUT_DIR"
    if [ "$ANONYMIZE" = true ]; then
        log_info "Anonymization: enabled"
        log_info "Replacements file: $REPLACEMENTS_FILE"
        log_info "Anonymized output: $ANON_NAME"
    else
        log_info "Anonymization: disabled (use --anon to enable)"
    fi
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN MODE - No files will be created"
    fi
    echo ""
fi

# Step 1: Generate the actual resume PDF
log_info "Generating ${OUTPUT_PDF}..."

if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would execute:"
    echo "pandoc \"$INPUT_MD\" \\" >&2
    echo "  --from markdown+raw_html \\" >&2
    echo "  --to=html5 \\" >&2
    echo "  --standalone \\" >&2
    echo "  --css=\"$CSS_FILE\" \\" >&2
    echo "  --quiet \\" >&2
    echo "  -o - | weasyprint --quiet - \"$OUTPUT_PDF\"" >&2
else
    execute_with_timeout 300 "Converting markdown to PDF" \
        pandoc "$INPUT_MD" \
        --from markdown+raw_html \
        --to=html5 \
        --standalone \
        --css="$CSS_FILE" \
        --quiet \
        -o - | weasyprint --quiet - "$OUTPUT_PDF"
fi

if [ $? -eq 0 ] && [ "$DRY_RUN" = false ]; then
    size=$(get_file_size "$OUTPUT_PDF")
    log_success "Successfully generated: $OUTPUT_PDF ($(format_file_size $size))"
elif [ "$DRY_RUN" = false ]; then
    log_error "Error generating $OUTPUT_PDF. Check pandoc and weasyprint installation."
    exit 1
fi

if [ "$QUIET" = false ]; then
    echo ""
fi

# Step 2: Create anonymized version (if requested)
if [ "$ANONYMIZE" = true ]; then
    log_info "Creating anonymized version..."

    # Check if replacements file exists
    if [ ! -f "$REPLACEMENTS_FILE" ]; then
        log_error "$REPLACEMENTS_FILE not found!"
        echo "This file is required for anonymization. Create it with format: original_text|replacement_text"
        exit 1
    fi

    # Validate replacements file format
    validate_replacements

    # Copy the original resume to create anonymized version
    if [ "$DRY_RUN" = false ]; then
        cp "$INPUT_MD" anon_resume.md
    fi

    # Anonymize personal information
    log_info "Anonymizing personal information..."

    replacement_count=0

    # Read replacements from file and apply them
    while IFS='|' read -r original replacement || [ -n "$original" ]; do
        # Skip comments and empty lines
        if [[ "$original" =~ ^#.*$ ]] || [ -z "$original" ]; then
            continue
        fi

        # Sanitize patterns for sed safety
        escaped_original=$(sanitize_for_sed "$original")
        escaped_replacement=$(sanitize_for_sed "$replacement")

        # Apply the replacement
        if [ "$DRY_RUN" = false ]; then
            safe_sed "s|${escaped_original}|${escaped_replacement}|g" anon_resume.md
        fi

        ((replacement_count++))

        if [ "$QUIET" = false ] && [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would replace: '$original' → '$replacement'"
        fi
    done < "$REPLACEMENTS_FILE"

    log_success "Applied $replacement_count replacements"

    # Step 3: Generate anonymized PDF
    anon_output="${OUTPUT_DIR}/$ANON_NAME"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would execute:"
        echo "pandoc anon_resume.md \\" >&2
        echo "  --from markdown+raw_html \\" >&2
        echo "  --to=html5 \\" >&2
        echo "  --standalone \\" >&2
        echo "  --css=\"$CSS_FILE\" \\" >&2
        echo "  --quiet \\" >&2
        echo "  -o - | weasyprint --quiet - \"$anon_output\"" >&2
    else
        execute_with_timeout 300 "Generating anonymized PDF" \
            pandoc anon_resume.md \
            --from markdown+raw_html \
            --to=html5 \
            --standalone \
            --css="$CSS_FILE" \
            --quiet \
            -o - | weasyprint --quiet - "$anon_output"
    fi

    if [ $? -eq 0 ] && [ "$DRY_RUN" = false ]; then
        size=$(get_file_size "$anon_output")
        log_success "Successfully generated: $anon_output ($(format_file_size $size))"
        if [ "$KEEP_TEMP" = false ]; then
            log_success "Temporary file removed (anon_resume.md)"
        fi

        if [ "$QUIET" = false ]; then
            echo ""
            echo "========================================="
            echo "Generated files:"
            echo "  • $OUTPUT_PDF ($(format_file_size $(get_file_size "$OUTPUT_PDF")))"
            echo "  • $anon_output ($(format_file_size $size))"
            echo "========================================="
        fi
    elif [ "$DRY_RUN" = false ]; then
        log_error "Error generating $anon_output"
        exit 1
    fi
else
    if [ "$QUIET" = false ]; then
        echo ""
        echo "========================================="
        echo "Generated files:"
        if [ "$DRY_RUN" = false ]; then
            echo "  • $OUTPUT_PDF ($(format_file_size $(get_file_size "$OUTPUT_PDF")))"
        else
            echo "  • $OUTPUT_PDF (would be generated)"
        fi
        echo "========================================="
        echo ""
        echo "To also generate an anonymized version, use: $0 --anon $INPUT_MD"
    fi
fi

# Final success message
if [ "$DRY_RUN" = true ]; then
    log_success "Dry run completed successfully"
else
    log_success "Resume generation completed successfully"
fi
