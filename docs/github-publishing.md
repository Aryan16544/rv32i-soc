# GitHub Publishing Guide

Use this checklist when you are ready to publish the SoC.

## Before You Push

1. Review `README.md` and make sure the project name and description are the ones you want.
2. Add a `LICENSE` file before making the repository public.
3. Check that your demo program and screenshots match the version you want people to see.

## Initialize Git

Run these commands from the project root:

```powershell
git init
git add .
git commit -m "Initial open-source release"
```

The included `.gitignore` skips local Vivado output, `node_modules`, and archived snapshot folders.

## Create The Remote Repository

If you create the repository on GitHub first, connect it like this:

```powershell
git branch -M main
git remote add origin https://github.com/<your-username>/<repo-name>.git
git push -u origin main
```

If you use GitHub CLI, this also works:

```powershell
gh repo create <repo-name> --public --source . --remote origin --push
```

## Good Follow-Up Steps

1. Add a short release note in the GitHub description.
2. Tag the first stable version.
3. Add screenshots of simulation output, UART terminal output, or FPGA bring-up.
4. Add a license badge and board photo later if you want a nicer project page.

