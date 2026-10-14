# Unjam: The Last Slot — Rules & Movement Specification

This is the single canonical rule set. It is implemented **only** in
`src/core/board_state.gd` (`BoardState`); the UI, hint system, solver and level
validator all call that code, so there are no per-scene variations.

## Board representation

* A board is a list of **trays** (2–10 per level), indexed `0..n-1`.
* A tray is a **stack** with a fixed **capacity** `cap` (2–6). Index 0 is the
  bottom, the last element is the **top**.
* An **object** is a packed integer:

  | bits   | meaning |
  |--------|---------|
  | 0–7    | type id `0..types-1` (each type has a colour *and* a shape) |
  | 8–15   | lock: `0` none, `k+1` = "opens when a tray of type `k` is cleared" |
  | 16–31  | thaw: `0` none, `n` = frozen until the move counter reaches `n` |

* Per-tray options: `accepts` (only this type may be placed; `-1` = any) and
  `source_only` (objects can be taken from it but never placed into it).
* Global mutable state: `moves` (valid moves made) and `cleared_mask`
  (bit `k` set once a tray of type `k` has been cleared).
* Level option `max_moves` (0 = unlimited).

## Accessibility (which object can be picked up)

Only the **top** object of a tray can be picked up. Objects beneath it are
*blocked* until it moves. The top object additionally cannot be picked if it is

* **locked** – its lock key `k` is set and bit `k` of `cleared_mask` is not, or
* **frozen** – `moves < thaw`.

## Valid move: `check_move(from, to)`

A move takes the top object of tray `from` and puts it on tray `to`. It is
legal only if **all** hold (checked in this order; the first failing check is the
reported reason):

1. The level is not already won, and `moves < max_moves` when a limit exists.
2. Both indices are valid trays and `from != to`.
3. `from` is non-empty and its top object is neither locked nor frozen.
4. `to` is not `source_only`.
5. If `to.accepts != -1`, the object's type equals `to.accepts`.
6. `to` is not full (`size < cap`).
7. `to` is empty **or** its top object has the **same type** as the moved one.

Illegal moves never modify any state. There is exactly one object moved per move.

## Applying a move

1. Remove the top of `from`, push it onto `to`, `moves += 1`.
2. **Clear rule:** if `to` is now **full** and all its objects share one type,
   the tray is **cleared**: it becomes empty, and bit `type` of `cleared_mask`
   is set (this opens any locks that name that type).

## Win, failure

* **Won**: every tray is empty (every object has been sorted into a cleared tray).
  Win is only evaluated from state, never from an animation callback.
* **Failed** (and not won): either `max_moves > 0 and moves >= max_moves`, or
  there is **no legal move** at all (deadlock).
* Undo is always allowed after a failure; it returns the game to `PLAYING`.
* A position that still has legal moves but can never be finished is **not**
  detected as failure by the game (that would need a full search every move);
  the Hint button runs the solver and tells the player honestly if the position
  is a dead end ("This can't be finished") without charging coins.

## Undo and restart

* Before every valid move a snapshot `{stacks, moves, cleared_mask}` is pushed
  to history. **Undo** pops it and restores it exactly (including move count,
  cleared types – hence locks – and thaw counters, which derive from `moves`).
* **Restart** restores the level's initial snapshot and clears history.
  The UI asks for confirmation when the move count is above zero.

## Mechanics by stage

| Stage | Mechanic | Rule |
|------:|----------|------|
| 1 | Basic sorting | the rules above |
| 2 | Limited capacity | trays have different capacities; free slots are scarce |
| 3 | Move limits | `max_moves`; Undo gives moves back |
| 4 | Locks | padlock shows the shape that opens it |
| 5 | Special trays | reserved (`accepts`) and one-way (`source_only`) trays |
| 6 | Ice | frozen objects show the moves remaining |
| 7 | Mastery | combinations |

## The Last Slot

The HUD shows *Free slots* (total capacity minus objects on the board). When it
reaches 1 it reads **"Last slot!"** — the player must decide which object takes
the final free position before space is made for the rest.

## Economy

* Start balance 30 coins. A level's **first** completion pays
  `15 + 5 × stars` coins; **replays pay nothing** (they may only improve stars).
* Stars: ≤ 125 % of par → 3, ≤ 175 % → 2, otherwise 1 (par = length of the
  validated shortest solution).
* A hint costs 15 coins and is charged only when a legal hint is produced.
