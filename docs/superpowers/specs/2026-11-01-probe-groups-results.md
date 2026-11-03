# Group probe results (onPC 2.5.1.1, 2026-11-03)

Logs: `probe/2.5.1.1_26-11-03T16.44.txt` (v0.2), `probe/2.5.1.1_26-11-03T16.51.txt` (v0.3).
Test show: group 10 "ESPRITE XYZ" = fixtures 101–112, XYZ preset 2.37.

| Test | Result | Used for |
|---|---|---|
| G0 | `DataPool().Groups:Children()` lists every group with `.no` and `.name` (40 groups). | Group list in the add picker. |
| G1 | `Groups[10]` is class Group: `SelectionData` and `Selection` are tables, `Fixtures` is nil, no children. | — |
| S1/S2 | `SelectionData` (and `Selection`, same content) = one entry per member: `{ sf_index = n, grid = { x, y, z, inv, x_inv, y_inv, z_inv } }`; group 10 → `sf_index` 2…13, grid x 0…11. | **Membership:** `GetSubfixture(sf_index).fid`, the same index space `patch.ts` already uses. No selection touched. |
| S3 | `Group:Count()` = 0 (counts children, not members). | Not used. |
| G2 | `ObjectList("Group 10")` returns the Group itself. | Rejected. |
| G3 | `SelFix Group 10` works and restored an empty selection exactly, but echoes in the command line. | Rejected: S1 makes it unnecessary. |
| P1 | Selecting 101 + 102 then attribute commands programs both. | Group marker taps (`ProgramGroup`). |
| X1 | Preset 2.37 attributes: `XYZ_Flip, XYZ_MArker, XYZ_X, XYZ_Y, XYZ_Z` (needs the `pool.no` address). | Picker's "has XYZ" test (`XYZ_` prefix). |
| C1 | Global theme colours include `SuccessText`, `WarningText`, `ErrorText`, `Selected`. | Tick colours. |

Not yet seen on a console: that `sf_index` 2 is fixture 101 (inferred from the shared index space and
the 12 entries in grid order). Checklist items 37 (yellow ticks on the right fixtures) and 44 (group row follows member changes) cover it.
