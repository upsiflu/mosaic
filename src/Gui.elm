module Gui exposing 
    ( Item (..)
    , nest_collapsed
    , nest_expanded
    , view

    , Document (..)
    , collapsed_document
    , expanded_document
    , with_toolbar
    , with_position
    , with_delta
    , with_draggability
    , with_attributes
    , with_class
    , with_info

    , Mode
    , State (..)
    , Control (..)
    , Toolbar
    , toolbar

    , Face
    , icon
    , literal
    , sample
    , with_hint
    , view_face

    , Position
    , midpoint
    , add_delta

    , Delta
    , zero
    , running_delta
    , final_delta

    , DragTrace(..)
    , new_trace
    )



import W3.Html exposing (..)
import W3.Html.Attributes exposing (class, title, disabled, style, draggable )
import W3.Aria.Attributes exposing (pressed, checked, true, false, expanded, orientation, horizontal)
import W3.Aria as Aria

--import VirtualDom

import Json.Decode as Decode exposing (float)
import Json.Decode.Pipeline exposing (required)

--import Draggable
--import Draggable.Events

import Html as Untyped



{- This module exposes functions to build and view a graphical user interface during the 'view' phase, generally stateless. -}




type Item msg
    = Item 
        ( Face msg ) 
        ( List (GlobalAttributes {} msg ) ) 
        ( List ( Node FlowContent msg ) )



-- create

nest_expanded : Document { mode | expanded : Mode } msg -> Item msg
nest_expanded ( Document face attributes contents ) =
    Item face 
        ( Aria.document [ expanded (Just True) ] attributes ) 
        contents

nest_collapsed : { how_to_expand : msg, controls : List ( Control msg ) } -> Document { mode | collapsed : Mode } msg -> Item msg
nest_collapsed overlay ( Document face attributes contents ) =
    Item face 
        ( Aria.document [ expanded (Just False) ] ( ondblclick overlay.how_to_expand :: attributes ) ) 
        ( List.map view_control overlay.controls ++ contents )


-- view

view : State msg -> Item msg -> Untyped.Html msg
view state ( Item face attributes contents ) = 
    let hint = face |> \( Face h _ ) -> title h
        ( incipit, explicit ) =
            case state of
                Deselected how_to_reselect how_to_focus -> 
                    ( Aria.checkbox 
                        [ checked false ] 
                        [ hint, onclick how_to_reselect ]
                    , [ onclick how_to_focus ] 
                    )

                Selected how_to_deselect how_to_focus  -> 
                    ( Aria.checkbox 
                        [ checked true ] 
                        [ hint, onclick how_to_deselect]
                    , [ onclick how_to_focus
                      , class ["gui selected pattern"] ] 
                    )

                Focused how_to_assert_focus -> 
                    ( Aria.checkbox 
                        [ checked true ] 
                        [ hint, onclick how_to_assert_focus, class ["gui focused"] ]
                    , [ onclick how_to_assert_focus
                    , class ["gui focused pattern"] ] 
                    )
    in 
    button incipit [ view_face face ] :: contents
    |> div ( explicit ++ attributes )
    |> toNode






type Mode = Mode


type State msg
    = Deselected msg msg
    | Selected msg msg
    | Focused msg





type Control msg
    = Toggle ( Face msg ) { toggle : msg, is_on : Bool }
    | Check { hint : String, toggle : msg, is_checked : Bool }
    | Input ( Face msg ) { set : String -> msg, is_set : Bool }
    | Compose ( Face msg ) (List (Control msg))


-- view

view_control : Control msg -> Node FlowContent msg
view_control control =
    let title_hint ( Face hint _ ) = title hint in
    case control of
        Toggle face t ->
            button 
                ( Aria.button
                    [ if t.is_on then pressed true else pressed false ]
                    [ onclick t.toggle, title_hint face ]
                )
                [ view_face face ]
        _ ->
            button (Aria.button [] [ disabled True ]) [text "(this control's view is not yet implemented)"]





-- TOOLBAR


type alias Toolbar msg = 
    Node FlowContent msg


-- create

toolbar : Face msg -> List ( Control msg ) -> Toolbar msg
toolbar label_face =
    let title_hint ( Face hint _ ) = title hint in
    List.map view_control
        >> (::) (label [] [ view_face label_face])
        >> List.map (List.singleton >> li []) 
        >> menu
            ( Aria.toolbar [ orientation horizontal, expanded (Just True) ] [ class ["gui"], title_hint label_face ] )





-- FACE


type Face msg
    = Face String (Node PhrasingContent msg)




-- create
  
icon : String -> String -> Face msg
icon hint string =
    span 
        [ class ["icon", "static"] ] 
        [ span [ class ["static", "material-icons"] ] [ text string ] ]
        |> Face hint

literal : String -> Face msg
literal string =
    Face "" (text string)

sample : String -> String -> List (Node PhrasingContent msg) -> Face msg
sample hint name samples =
    span [ class [ "preview", "static" ] ] 
        [ span [ class [ name, "static" ] ] 
            samples 
        ]
        |> Face hint


-- map

with_hint : String -> Face msg -> Face msg
with_hint hint (Face _ html) =
    Face hint html


-- view

view_face : Face msg -> Node PhrasingContent msg
view_face ( Face description descendant ) =
    span [ class ["face"], title description ] [ descendant ]









{- To limit certain functions on subsets of the Document type, `mode` provides a flexible phantom type parameter. -}
type Document mode msg
    = Document ( Face msg ) ( List (GlobalAttributes {} msg ) ) ( List ( Node FlowContent msg ) )


-- create

collapsed_document : Face msg ->  List (GlobalAttributes {} msg ) -> List ( Node FlowContent msg ) -> Document { mode | collapsed : Mode } msg
collapsed_document = Document

expanded_document : Face msg -> List (GlobalAttributes {} msg ) -> List ( Node FlowContent msg ) -> Document { mode | expanded : Mode } msg
expanded_document = Document


-- map

with_toolbar : Toolbar msg -> Document { mode | expanded : Mode } msg -> Document { mode | expanded : Mode } msg
with_toolbar t ( Document face attributes contents ) =
    Document face attributes ( t::contents )

with_position : Position -> Document mode msg -> Document mode msg
with_position { x, y } =
    with_attributes
        [ style "left" (String.fromFloat x ++ "px")
        , style "top" (String.fromFloat y ++ "px")
        ]

with_class : String -> Document mode msg -> Document mode msg
with_class str = with_attributes [ class [str] ]

with_delta : Delta -> Document mode msg -> Document mode msg
with_delta { x, y } =
    with_attributes
        [ style "transform" 
            ("translate(" ++ String.fromInt x ++ "px, " ++ String.fromInt y ++ "px)")
        ]

with_info : Face msg -> Document { mode | expanded : Mode } msg -> Document { mode | expanded : Mode } msg
with_info info ( Document face attributes contents ) =
    Document face attributes ( (span [ class ["gui","info"] ] [view_face info])::contents )

    


with_attributes :  List (GlobalAttributes {} msg ) -> Document mode msg -> Document mode msg
with_attributes new_attributes ( Document face attributes contents )=
    Document face (new_attributes++attributes) contents




with_draggability : (DragTrace -> msg) -> (DragTrace -> msg) -> 
                    DragTrace -> 
                    Document mode msg -> Document mode msg
with_draggability how_to_drag how_to_settle trace =
    let decode_delta =
            Decode.succeed DragCoordinates
                |> required "pageX" float
                |> required "pageY" float
                |> Decode.map coordinates_to_delta
        send message =
            Decode.map (\updated_trace -> Event (message updated_trace) False False)
            
        create_zero_trace =
            decode_delta
                |> Decode.map (\delta -> trace_drag delta Zero )
                |> send how_to_drag
        append_if_running =
            decode_delta
                |> Decode.map (\delta -> trace_drag delta trace )
                |> send how_to_drag
        decode_dragend =
            decode_delta
                |> Decode.map (\delta -> trace_drag delta trace )
                |> Decode.map done_drag_trace
                |> send how_to_settle
        decode_dragexit =
            decode_delta
                |> Decode.map (\delta -> trace_drag delta trace )
                |> Decode.map cancel_drag_trace
                |> send how_to_settle

    in 
    with_attributes
        [ style "cursor" "move"
        , style "touch-action" "none"
        --, draggable True
        , on "pointerdown" create_zero_trace
        , on "pointermove" append_if_running
        , on "pointerup" decode_dragend
        , on "pointerout" decode_dragexit
        ]






type DragTrace
    = Zero
    | Running Delta (List Delta) Delta
    | Canceled Delta (List Delta) Delta
    | Done Delta (List Delta) Delta


--create

new_trace : DragTrace
new_trace = Done zero [] zero


-- map

trace_drag : Delta -> DragTrace -> DragTrace
trace_drag delta trace =
    case trace of
        Zero -> Running delta [] delta
        Running final list initial -> Running delta ( final :: list ) initial
        _ -> trace

done_drag_trace : DragTrace -> DragTrace
done_drag_trace trace =
    case trace of
        Zero -> Zero
        Running final list initial -> Done final list initial
        _ -> trace

cancel_drag_trace : DragTrace -> DragTrace
cancel_drag_trace trace =
    case trace of
        Zero -> Zero
        Running final list initial -> Canceled final list initial
        _ -> trace










type alias Position =
    { x : Float
    , y : Float
    }

-- create

midpoint : Position
midpoint = Position 0 0 


-- map

add_delta : Delta -> Position -> Position
add_delta delta { x, y } =
    Position (x + toFloat delta.x) (y + toFloat delta.y)






type alias DragCoordinates =
    { pageX : Float
    , pageY : Float
    }


-- create

coordinates_to_delta : DragCoordinates -> Delta
coordinates_to_delta { pageX, pageY } =
    Delta (round pageX) (round pageY)




type alias Delta =
    { x : Int 
    , y : Int
    }


-- create

zero : Delta
zero = { x = 0, y = 0 }

running_delta : DragTrace -> Delta
running_delta trace =
    case trace of
        Zero -> zero
        Running final  _ initial -> diff final initial
        Canceled final _ initial -> diff final initial
        Done _ _ _ -> zero

final_delta : DragTrace -> Delta
final_delta trace =
    case trace of
        Zero -> zero
        Running _ _ _ -> zero
        Canceled _ _ _ -> zero
        Done final _ initial -> diff final initial


-- map

diff : Delta -> Delta -> Delta
diff final initial =
    Delta (final.x-initial.x) (final.y-initial.y)





