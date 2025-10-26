# Resume Generator

> *"It's just a wrapper around pandoc and weasyprint!"* — Yes, it certainly is!

A robust, cross-platform script that transforms your markdown resume into a clean, professional PDF.

## Why This Exists

Sure, you *could* memorize the pandoc incantation to convert markdown to HTML to PDF. You *could* manually edit your personal details every time you want to share your resume publicly. You *could* remember which CSS file you were using six months ago.

Or you could use this script and focus on the important stuff — like writing a good resume and getting the job.

## Features

- ✅ **Professional Output**: Clean, consistent PDF formatting that looks great everywhere
- ✅ **Optional Anonymization**: Generate public-safe versions with personal details replaced
- ✅ **Print-Optimized Design**: Looks great on screen and prints perfectly
- ✅ **Flexible Styling**: Use the included CSS or bring your own
- ✅ **Smart File Management**: Automatic overwrite protection and cleanup
- ✅ **Developer-Friendly**: Dry run mode, verbose logging, and extensive validation

## Quick Start

1. **Install dependencies** (see [Installation](#installation) below)
2. **Copy the example resume**: `cp example_resume.md my_resume.md`
3. **Edit with your information**: Open `my_resume.md` and replace the example content
4. **Generate your PDF**: `./resgen.sh my_resume.md`

That's it! You'll have a professional `my_resume.pdf` ready to go.

## Installation

### Dependencies

You'll need two tools that do the heavy lifting:

#### pandoc
Converts your markdown to HTML.

```bash
# macOS
brew install pandoc

# Ubuntu/Debian
sudo apt-get install pandoc

# Other Linux
# Download from https://pandoc.org/installing.html
```

#### weasyprint
Converts HTML to PDF.

```bash
# Install via pip (recommended)
pip install weasyprint

# Or via conda
conda install weasyprint

# macOS via homebrew (alternative)
brew install weasyprint
```

### Verify Installation

```bash
# Check that everything's working
pandoc --version
weasyprint --version

# Test the script
./resgen.sh --help
```

## Usage

### Basic Usage

```bash
# Generate a simple PDF
./resgen.sh my_resume.md

# Generate both original and anonymized versions
./resgen.sh --anon my_resume.md

# Same as above using short flag
./resgen.sh -a my_resume.md

# Use custom CSS
./resgen.sh --css custom-style.css my_resume.md

# Quiet mode (minimal output)
./resgen.sh --quiet my_resume.md

# Stacked flags: force + anon + quiet
./resgen.sh -faq my_resume.md
```

### Advanced Options

```bash
# Custom output directory
./resgen.sh --output-dir ./pdfs my_resume.md

# Custom anonymized filename
./resgen.sh --anon --anon-name public_resume.pdf my_resume.md

# Custom replacements file
./resgen.sh --anon --replacements my_replacements.txt my_resume.md

# Preview without generating (dry run)
./resgen.sh --dry-run --anon my_resume.md

# Keep temporary files for debugging
./resgen.sh --keep-temp --anon my_resume.md

# Auto-overwrite files (useful for automation)
./resgen.sh --force --anon my_resume.md
```

### Full Options Reference

```bash
./resgen.sh [OPTIONS] <markdown_file>

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
  --help, -h             Show help message

NOTE: Short flags can be stacked together (e.g., -faq for --force --anon --quiet)
```

## File Structure

```
resume/
├── resgen.sh           # The main script
├── resume.css                   # Default styling
├── example_resume.md           # Template to copy and customize
├── example_replacements.txt    # Example anonymization rules
├── replacements.txt            # Your personal anonymization rules (gitignored)
├── my_resume.md               # Your actual resume (gitignored)
└── README.md                  # This file
```

## Creating Your Resume

### 1. Start with the Example

Copy the example resume to get started:

```bash
cp example_resume.md my_resume.md
```

The example includes:
- **Clean HTML structure** for consistent formatting
- **Flexible layout** with CSS flexbox
- **Professional formatting** for contact info, experience, education
- **Clean typography** that prints well

### 2. Customize the Content

Edit `my_resume.md` with your information. The format includes:

- **Header with contact info** using flexbox layout
- **Professional summary** section
- **Technical skills** in organized lists
- **Experience** with company links and date ranges
- **Education** section

### 3. Generate and Iterate

```bash
# Generate your PDF
./resgen.sh my_resume.md

# Make changes and regenerate
# The script will ask before overwriting existing files
```

## Anonymization

For sharing your resume publicly (GitHub, portfolio sites, etc.), you can generate an anonymized version:

### 1. Set Up Replacements

Copy the example and customize:

```bash
cp example_replacements.txt replacements.txt
```

Edit `replacements.txt` with your personal information:

```
# Format: original_text|replacement_text
John Doe|Your Name
555-123-4567|999-999-9999
john.doe@email.com|your.email@example.com
TechCompany Inc.|Large Tech Corporation
San Francisco, CA|Major City, ST
```

### 2. Generate Anonymized Version

```bash
./resgen.sh --anon my_resume.md
```

This creates:
- `my_resume.pdf` (your actual resume)
- `anon_resume.pdf` (anonymized version)

## Customizing the CSS

The included `resume.css` is designed to be:
- **Clean and readable**: Well-structured layout that's easy to scan
- **Print-optimized**: Looks great on paper and PDF
- **Professional**: Conservative styling that works everywhere

### Using Custom CSS

```bash
./resgen.sh --css my-custom-style.css my_resume.md
```

### CSS Customization Tips

- Keep the HTML structure from `example_resume.md` for consistent formatting
- Use the `.flex-container` class for two-column layouts
- Modify colors, fonts, and spacing in your CSS file
- Test print output — what looks good on screen might not print well

## Troubleshooting

### Common Issues

**"pandoc: command not found"**
```bash
# Install pandoc (see Installation section)
brew install pandoc  # macOS
sudo apt-get install pandoc  # Linux
```

**"weasyprint: command not found"**
```bash
# Install weasyprint
pip install weasyprint
```

**"Permission denied"**
```bash
# Make script executable
chmod +x resgen.sh
```

**PDF has weird formatting**
- Check that your CSS file exists and is valid
- Verify the markdown structure matches the example
- Use `--keep-temp` to debug the generated HTML

### Getting Help

```bash
# Check script version and options
./resgen.sh --help

# Test without generating files
./resgen.sh --dry-run my_resume.md

# Keep temporary files to debug
./resgen.sh --keep-temp my_resume.md
```

## Why This Approach?

### Clean, Professional Output

This script generates consistently formatted, professional resumes:

- Uses clean HTML structure with semantic tags
- Avoids overly complex layouts
- Generates consistent, predictable output
- Creates PDFs that look professional everywhere

### Workflow Benefits

- **Version Control**: Your resume is markdown — track changes with git
- **Consistency**: Same output every time, no "what font was I using?" moments
- **Automation**: Integrate into CI/CD, auto-generate on changes (use `--force` to skip prompts)
- **Privacy**: Easy anonymization for public sharing

### Professional Polish

- **Error Prevention**: Validates everything before generating
- **File Management**: Handles overwrites, cleanup, and organization
- **Cross-platform**: Works everywhere you work
- **Future-proof**: Markdown ages better than proprietary formats

## Contributing

This is a personal resume generator, but if you find bugs or have suggestions:

1. Check if it's a pandoc or weasyprint issue first
2. Test with the example files to isolate the problem
3. Include your OS, script version, and error messages

### Customization Ideas

- **Additional CSS themes**: Create alternative styling
- **Output formats**: Extend for HTML-only output
- **Integration**: Add hooks for automatic deployment
- **Validation**: Enhanced markdown linting
