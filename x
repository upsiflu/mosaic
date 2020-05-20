

U+250x	─	━	│	┃	┄	┅	┆	┇	┈	┉	┊	┋	┌	┍	┎	┏

U+251x	┐	┑	┒	┓	└	┕	┖	┗	┘	┙	┚	┛	├	┝	┞	┟

U+252x	┠	┡	┢	┣	┤	┥	┦	┧	┨	┩	┪	┫	┬	┭	┮	┯

U+253x	┰	┱	┲	┳	┴	┵	┶	┷	┸	┹	┺	┻	┼	┽	┾	┿

U+254x	╀	╁	╂	╃	╄	╅	╆	╇	╈	╉	╊	╋	╌	╍	╎	╏

U+255x	═	║	╒	╓	╔	╕	╖	╗	╘	╙	╚	╛	╜	╝	╞	╟

U+256x	╠	╡	╢	╠╣	╤	╥	╦	╧	╨	╩	╪	╫	╬	╭	╮	╯

U+257x	╰	╱	╲	╳	╴	╵	╶	╷	╸	╹	╺	╻	╼	╽	╾	╿

▼   ☚ ☛
▲
➧
➔
→
⇛
➠
➞
⤜⤚▶➛
◀⤙⤛
⬅



 ━━━▶ Synchronize.
 ──▶  Affect.
 :::: Shadow (of same name).
 [  ] event, resp. Message.




. Interop Diagram                                    ┆                      ┆
.                                                    ┆                      ┆
.                                                    ┆                      ┆
.                              ╔════════╗            ┆ ╻┏━━━━━━━━┓          ┆
.	           ╭─[ on_format ]─║ :::::: ◀━━━━━━━━━━━━━━┫┃ format ┃ ◀ user input
.              │               ╚════════╝            ┆ ╹┗━━━━━━━━┛          ┆
.              │                                     ┆      ▲               ┆
.	           │ ╭─────────────[ on_caret ]─────────────────╯               ┆
. apply format ▼ │                                   ┆                      ┆
.           ┏━━━━┷━━┓╻                               ┆  ╔═══════╗           ┆
user input ▶┃ fresh ┃┣━━━━━━━━━[ on_fresh ]━━━━━━━━━━━━━▶ ::::: ║           ┆
.           ┗━━━━━━━┛╹                               ┆  ╚═══════╝           ┆
.    overwrite ▲                                     ┆      │               ┆
.              │                                     ┆      │┄[ Finished ]  ┆
.              │                                     ┆      │               ┆
.              │                                     ┆      ▼               ┆
.              │                ╔═══════╗            ┆ ╻┏━━━━━━━┓╻          ┆  ╔═══════╗
.              ╰───[ on_stale ]─║ ::::: ◀━━━━━━━━━━━━━━┫┃ stale ┃┣━━━━━━━━━━━━━▶ ::::: ║
.                               ╚═══════╝            ┆ ╹┗━━━━━━━┛╹          ┆  ╚═══════╝
.                                                    ┆      ▲               ┆     │
.                                                    ┆      │               ┆     │┄(eventual synchronization)
.                                                    ┆      │┄[ Received ]  ┆     │
.                                                    ┆      │               ┆     ▼
.                                                    ┆  ╔═══════╗           ┆ ╻┏━━━━━━━━━━━┓
.                                                    ┆  ║ ::::: ◀━━━━━━━━━━━━━┫┃ canonical ┃
.                                                    ┆  ╚═══════╝           ┆ ╹┗━━━━━━━━━━━┛
.                                                    ┆                      ┆
.        Squire Instance   Custom Element Node       ╿      Elm Article     ╿  Server




   Elm             Cmd    update     Msg          view
				   ⬇                              ⬇
				   port toEditor                  custom-editor
				                                  

                 ⬍
                   ⬆️ ↓