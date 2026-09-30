# AI Workshop - OpenEdge ABL Project

Sample OpenEdge ABL 12.8 project used in the AI workshop, based on the ProjectGengar Step-16 branch.

## Contents

- `src/business/` - Business entity classes (`CustomerEntity`, `EntityFactory`) and the `CustomerDataset.i` include
- `src/*.w` - GUI windows (`CustomerWin.w`, `ItemWin.w`)
- `.windsurf/` - Windsurf rules and workflows for ABL development
- `doc/` - Documentation of the business entity pattern
- `dump/` - sports2000 database schema summary

## Requirements

- OpenEdge 12.8
- sports2000 database (see `build.xml`, target `db`, which uses PCT to create it)
