---
name: dev-kit-mermaid-export
description: Convert Mermaid .mmd diagrams to .svg files, especially for article assets.
---

## Purpose
Convert Mermaid diagrams to SVG assets using the project tooling.


## Required Inputs
- One or more `.mmd` file paths.


## Config
- Inputs: source `.mmd` files and optional output directory.
- Outputs: `.svg` files alongside or under assets directory.


## Logic
- Identify `.mmd` files to convert.
- Run the mermaid export command.
- Report generated files.


## Schema
- Inputs: file paths
- Outputs: svg files
- Format: file artifacts


## Output Rules
- List generated files.
