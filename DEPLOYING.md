# Deploying to Specific Platforms

> This document is intended for documenting caveats for deploying in different platforms.
> It's contents are intended to be filled by users, submitting PR with their experiences, this will then be reviewed and merged if found it's indeed a best practice.

* Format of the contribution:

> # Name of the Platform
>
> ## Descriptive title of specific caveat
>
> > Description of the issue
>
> Steps to solve:
>
> 1. Do ...
> 2. Then ...
> 3. After ...
>
> Contributed by @your_username

---

# Netlify

## Requirements for Build

> Minimum requirements for a clean build of a Contentful Middleman app on Netlify

Steps to solve:

1. add `.*-space-hash` to .gitignore
2. add `/data` to .gitignore
3. add a .ruby-version file
4. add a .nvmrc file
5. Netlify Site > Settings > Deploy Settings > Build Command: `middleman contentful --rebuild && middleman build`

> Contributed by @joshRpowell

---

# Placeholder Platform

## Placeholder Caveat

> Placeholder description

Steps to solve:

1. Do ...
2. Then ...
3. After ...

> Contributed by @...

---
