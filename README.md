# VendorCollector

A lightweight World of Warcraft addon that shows you exactly what you're missing from any vendor. No more flipping through pages wondering what you still need.

## What it does

When you open a vendor, click the **VendorC** tab (or enable auto-open) to see a clean list of every **uncollected** item across all vendor pages in one scrollable panel:

- **Mounts, toys, transmog, heirlooms, battle pets, recipes, housing decor** - if you've already learned it, it's hidden
- **Buyable items** are shown in full color, sorted cheapest first
- **Unbuyable items** are dimmed so you know what to work toward
- **Ensembles** - fully collected ensembles are hidden; partially or uncollected ones are shown
- **Cost summary** in the footer showing total cost, your current balance, and the difference

## Features

- Scans **all vendor pages** at once
- Click any item to **purchase** it directly (with confirmation prompt)
- Hover for the **full tooltip**
- **Settings panel** - click the Settings button in the top-right to configure:
  - **Auto-open** - opens the panel automatically with every vendor (skips if nothing to collect)
  - **Skip buy confirmation** - purchase items instantly on click, no prompt (requires confirmation to enable)
- Supports gold and currency vendors
- **ElvUI compatible**
- Zero configuration, no dependencies

## Installation

Drop the `VendorCollector` folder into your `Interface/AddOns` directory, or install via CurseForge.
