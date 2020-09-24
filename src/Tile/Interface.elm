module Tile.Interface exposing 
    ( Msg(..)
    , Mode(..)
    , mode
    , map_mode)

{-| Selection and Focus are relations of a `Mosaic` towards an instanciated `Tile`.
This module is separate from the Mosaic module so that the Tile module as well as its contents can import the types and functions and differenciate its `view`.

@docs Mode, mode, map_mode

@docs Msg
-}

{-|-}
type Msg
    = WalkedAway
    | WalkedHere


{-| The three available modes when viewing a tile 
in a context such as the mosaic.
-}
type Mode how_to_message
    = Normal
    | Selected
    | Editor how_to_message

{-| a Tile's Mode, given a message transformer and a set of conditions. -}
mode : (specific -> general) -> { selected : Bool, editing : Bool } -> Mode (specific -> general)
mode how_to_message conditions
    = case ( conditions.selected, conditions.editing ) of
        ( False, _ ) -> 
            Normal
        ( True, False ) ->
            Selected
        ( True, True ) ->
            Editor how_to_message

{-|-}
map_mode : (specific -> intermediate) -> Mode (intermediate-> general) -> Mode (specific -> general)
map_mode fu intermediate_mode =
    case intermediate_mode of
        Editor how_to_message -> Editor (fu >> how_to_message )
        Selected -> Selected
        Normal -> Normal
