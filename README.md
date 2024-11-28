# tetris

tetris in zig

## Run the game

> The game can be played in single-player or multi-player.

- Single player

```bash
./tetris
```
- Multi player

```bash
./tetris [your listen address] [player address ...]
```

> Multi player uses UDP to sync boards and scores

## Play the game

Keys:
- `Up`, `w`: rotate current shape
- `Down`, `s`: move shape down
- `Left`, `a`: move shape left
- `Right`, `d`: move shape right
