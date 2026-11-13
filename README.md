# Skill-Up Colors

![Skill-Up Colors](art/curseforge-logo.png)

**Recipe names colored by skill-up chance**, made for WoW: Forever.

| Color | Meaning |
| --- | --- |
| **Orange** | Always gives a skill point |
| **Yellow** | Usually gives a skill point |
| **Green** | Sometimes gives a skill point |
| Normal | No more skill points (left as the game shows it) |

- Recipe names in the profession window's list, instead of plain white.
- The craftable count after a name (the "[2]"), in the same color.
- The big recipe name on the right, instead of the item's rarity color.

No setup and no slash commands.

## Install

Download it from CurseForge, or copy this repository's files into a folder named
`SkillUpColors` inside `World of Warcraft\_forever_\Interface\AddOns\`.

## Options

At the top of `SkillUpColors.lua`:

| Setting | What it does |
| --- | --- |
| `COLOR_LIST` | Color the recipe list |
| `COLOR_COUNT` | Color the "[2]" count too |
| `COLOR_TITLE` | Color the recipe name on the right |
| `COLOR_GRAY` | Also turn recipes that give no more skill-ups gray |

The colors themselves are in `COLORS` just below.

## Changes

See [CHANGELOG.md](CHANGELOG.md).

## License

MIT, see [LICENSE](LICENSE).
