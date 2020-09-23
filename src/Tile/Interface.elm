module Tile.Interface exposing 
    ( Msg(..)
    , Appearance(..)
    , appearance
    , map_appearance)

{-| Stateless (interface) module for all Tiles.
@docs Msg

# Appearance
@docs Appearance, appearance, map_appearance
-}

{-|-}
type Msg
    = WalkedAway
    | WalkedHere


{-| The three available appearances when viewing a tile 
in a context such as the mosaic.
-}
type Appearance how_to_message
    = Normal
    | Selected
    | Editor how_to_message

{-| Calculates how a Tile appears, given a set of conditions. -}
appearance : (specific -> general) -> { selected : Bool, editing : Bool } -> Appearance (specific -> general)
appearance how_to_message conditions
    = case ( conditions.selected, conditions.editing ) of
        ( False, _ ) -> 
            Normal
        ( True, False ) ->
            Selected
        ( True, True ) ->
            Editor how_to_message

{-|-}
map_appearance : (specific -> intermediate) -> Appearance (intermediate-> general) -> Appearance (specific -> general)
map_appearance fu intermediate_appearance =
    case intermediate_appearance of
        Editor how_to_message -> Editor (fu >> how_to_message )
        Selected -> Selected
        Normal -> Normal
