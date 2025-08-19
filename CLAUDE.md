# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docusaurus-based documentation portal (tibhpc-docs) built using the Dyte documentation template. It's a comprehensive documentation site that appears to cover HPC (High Performance Computing) platform documentation including guides for platform usage, software applications, runtime environments, and job system management.

## Architecture & Structure

The project uses Docusaurus v3 with a custom multi-plugin setup. Documentation is organized into distinct sections, each handled as a separate Docusaurus plugin.

### Key Architecture Patterns

- **Multi-plugin docs structure**: Each documentation section has its own plugin configuration in the `docs` array at `docusaurus.config.js:23-185`, created using the `create_doc_plugin()` helper function  
- **Plugin-based architecture**: Uses the `create_doc_plugin()` function to standardize plugin creation with shared settings from `defaultSettings`
- **Client-side modules**: Custom startup scripts in `src/client/` for UI kit definitions and framework detection
- **Themed components**: Custom React components in `src/components/` and `src/theme/` with Tailwind CSS for styling
- **Complex redirect system**: Extensive URL redirect mapping in `docusaurus.config.js:227-441` for maintaining backward compatibility

## Common Commands

### Development
```bash
# Start development server
npm start
# or
npm run dev

# Build for production
npm run build

# Fix lint errors
npm run lint:fix

# Format code
npm run format

# Run spell check
npm run spell-check
```

### Documentation Commands
```bash
# Create version for Flutter (example)  
npm run docusaurus docs:version:flutter 1.2.3

# Clear Docusaurus cache
npm run clear

# Type checking
npm run typecheck

# Spell checking
npm run spell-check

# Format documentation files only
npm run format:docs
```

## Documentation Structure

### Documentation Categories
Based on the current content structure:
- **Getting Started**: Platform login, overview, basic HPC commands, file transfer
- **Platform Overview**: Chess portal, cluster queue, configuration, pricing, software list  
- **Runtime Environment**: Conda, modules, Singularity containers, virtual desktop
- **SLURM Job System**: Overview, salloc/sbatch/srun examples
- **Software Applications**: Various scientific software guides (AlphaFold, Gaussian, MATLAB, etc.)
- **AI Tools**: Transcription and other AI capabilities

### Legacy SDK Documentation (Template Inherited)
The codebase retains documentation structure for:
- **Web UI Kits**: UI Kit, React UI Kit, Angular UI Kit  
- **Web Core SDKs**: JavaScript, React Web Core
- **Mobile Core**: Android Core, iOS Core, Flutter Core, React Native Core
- **Mobile UI Kits**: Android, iOS, Flutter, React Native
- **Plugin SDK**: Web plugin development

### Editing Flow
1. **Main content**: Most documentation lives in `/docs/guides/` which maps to the `/guides` route
2. **SDK docs**: Individual SDK documentation in `/docs/[sdk-name]/` folders
3. **Versioned docs**: Some platforms use versioning (e.g., `flutter_versioned_docs/`) - check these first before editing main docs
4. **Sidebar updates**: Edit `sidebars-default.js` for most sections
5. **Navigation**: Update `src/sections.ts` for section menu changes (though this may not apply to HPC-focused content)

## Key Files & Folders

- `docusaurus.config.js:448-692` - Main Docusaurus configuration
- `docusaurus.config.js:23-185` - Individual plugin configurations via `docs` array
- `docusaurus.config.js:203-216` - `create_doc_plugin()` helper function for standardized plugin creation
- `docusaurus.config.js:227-441` - Complex redirect mappings for URL compatibility
- `src/sections.ts:23-181` - Section definitions and navigation structure (legacy from template)
- `sidebars-default.js` - Default sidebar configuration 
- `/docs/guides/` - Main documentation content (maps to `/guides` route)
- `/docs/[category]/` - Individual SDK/platform documentation folders
- `/src/components/` - Custom React components
- `/src/client/` - Client-side startup scripts (define-ui-kit.js, set-framework.js)
- `/src/css/` - Custom CSS including API reference styling
- `/static/` - Static assets and downloads
- `plugins/` - Custom Docusaurus plugins (Tailwind, Webpack, UI Kit reference)
- `patches/` - Package patches for dependency fixes

## Development Notes

### Adding New Documentation Sections
1. **For main guides**: Add content to `/docs/guides/[new-section]/` 
2. **For separate sections**: Add entry to `docs` array in `docusaurus.config.js:23-185` using the pattern:
   ```javascript
   {
     id: 'section-id',
     path: 'docs/section-folder',
     routeBasePath: '/section-url',
   }
   ```
3. **Apply plugin**: The section automatically gets processed by `create_doc_plugin()` 
4. **Update navigation**: Modify `src/sections.ts` if needed for section menus (mainly for SDK sections)

### Local Development Tips
- Use `npm run clear` if experiencing caching issues
- The project uses `@docusaurus/faster` for improved build performance
- Live reload works for most content changes
- Check browser console for any plugin loading errors

### Versioning (Inherited Feature)
The template supports versioning for platforms like Flutter:
1. Edit content in `/docs/flutter/` (current/next version)
2. Create version: `npm run docusaurus docs:version:flutter [version-number]`
3. Versioned content moves to `flutter_versioned_docs/version-[number]/`

### Technical Architecture Notes
- **Custom plugins**: Tailwind CSS integration, Webpack customizations, UI kit reference generation
- **Client modules**: `define-ui-kit.js` and `set-framework.js` run on client startup
- **Patches**: Uses `patch-package` for dependency fixes (see `/patches/`)
- **Theming**: Supports light/dark modes with custom CSS in `/src/css/`
- **Build optimization**: Uses SWC loader and experimental faster builds