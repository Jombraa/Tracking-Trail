# TaskTrail

A daily habit tracker styled as a **trail you walk** — each habit is a waypoint, finishing the day reaches the summit, and a streak is kept like a campfire burning.

**Live web app:** https://jombraa.github.io/Tracking-Trail/

## What's here

This repo holds two things:

- **Web app (PWA)** — the deployed version, served by GitHub Pages from the repo root. Open the live URL in a browser and "Add to Home Screen" to install it. Works offline.
  - `index.html` — the entire app (HTML/CSS/JS, no build step)
  - `manifest.webmanifest`, `sw.js`, `icon.png` — PWA manifest, service worker, icon
- **iOS app (SwiftUI)** — the original native version (`*.swift`, `TaskTrail.xcodeproj`). Shelved in favour of the web app, kept here for reference.

## Features

- Duolingo-style trail: tap a waypoint → start bubble → lesson screen (progress bar, task name + description, Complete).
- Groups are single nodes that reveal one step at a time and advance as you complete them; a progress ring shows how far through you are.
- Group **edit mode**: reorder steps, duplicate a step (choose how many), delete, retime.
- Per-task **countdown timers** with audible start/finish cues.
- Streak engine with weekly "freeze" provisions, a winding trail connector, confetti, and a custom line-icon set.
- Backup / restore (data is stored locally per device).

## Deploying

The web app is plain static files at the repo root. GitHub Pages (configured to serve `main` / root) redeploys automatically on every push to `main`.

```sh
git add -A && git commit -m "your change" && git push
```
